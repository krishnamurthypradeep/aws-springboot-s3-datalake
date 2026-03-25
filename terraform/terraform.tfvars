project_name = "aws-springboot-terraform-s3-complete"
region       = "us-east-2"

vpc_cidr              = "10.0.0.0/16"
public_subnet_a_cidr  = "10.0.1.0/24"
public_subnet_b_cidr  = "10.0.2.0/24"
private_subnet_a_cidr = "10.0.11.0/24"
private_subnet_b_cidr = "10.0.12.0/24"

bucket_name    = "pradeep-springboot-app-aws"
app_jar_s3_key = "prod/app.jar"
app_jar_path   = "../app/target/app.jar"

ec2_role_name     = "springboot-ec2-role"
alb_ingress_cidrs = ["0.0.0.0/0"]

app_port      = 8080
instance_type = "t3.micro"
app_env       = "prod"

alb_name          = "springboot-alb"
target_group_name = "springboot-tg"
health_check_path = "/actuator/health"