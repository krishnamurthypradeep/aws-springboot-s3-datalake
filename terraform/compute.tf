data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_a.id
  iam_instance_profile        = aws_iam_instance_profile.profile.name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = false

  user_data_replace_on_change = true

  user_data = <<-EOF2
#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -euxo pipefail

export AWS_REGION="${var.region}"

dnf update -y
dnf install -y java-21-amazon-corretto awscli

mkdir -p /opt/app
chown -R ec2-user:ec2-user /opt/app

echo "=== Checking IAM identity ==="
aws sts get-caller-identity || true

echo "=== Verifying JAR in S3 ==="
aws s3api head-object --bucket ${aws_s3_bucket.app_bucket.bucket} --key ${var.app_jar_s3_key}

echo "=== Downloading JAR ==="
aws s3 cp s3://${aws_s3_bucket.app_bucket.bucket}/${var.app_jar_s3_key} /opt/app/app.jar

echo "=== Stopping old app if running ==="
pkill -f 'java -jar /opt/app/app.jar' || true

echo "=== Starting Spring Boot app ==="
nohup java -jar /opt/app/app.jar \
  --server.port=${var.app_port} \
  --spring.profiles.active=${var.app_env} \
  --aws.region=${var.region} \
  --app.s3.bucket-name=${aws_s3_bucket.app_bucket.bucket} \
  --app.s3.default-prefix=${var.s3_default_prefix} \
  --app.s3.kms-key-id=${aws_kms_key.s3.arn} \
  > /opt/app/app.log 2>&1 &

sleep 30

echo "=== Java version ==="
java -version || true

echo "=== App files ==="
ls -l /opt/app || true

echo "=== Listening port ==="
ss -lntp | grep :${var.app_port} || true

echo "=== Health check ==="
curl -i http://localhost:${var.app_port}${var.health_check_path} || true
EOF2

  depends_on = [
    aws_s3_object.app_jar,
    aws_nat_gateway.nat,
    aws_route_table_association.private_a_assoc
  ]

  tags = {
    Name = "${var.project_name}-app-ec2"
  }
}
