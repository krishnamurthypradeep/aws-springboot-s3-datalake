variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "bucket_name" {
  description = "S3 bucket name for application artifacts and uploaded files"
  type        = string
  default     = "pradeep-springboot-app-aws"
}

variable "app_jar_path" {
  description = "Local path to the Spring Boot jar"
  type        = string
  default     = "../app/target/app.jar"
}

variable "app_jar_s3_key" {
  description = "S3 object key for uploaded jar artifact"
  type        = string
  default     = "artifacts/app.jar"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for private subnet A"
  type        = string
  default     = "10.0.11.0/24"
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for private subnet B"
  type        = string
  default     = "10.0.12.0/24"
}

variable "app_port" {
  description = "Application port on EC2"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "ALB target group health check path"
  type        = string
  default     = "/actuator/health"
}

variable "health_check_matcher" {
  description = "Expected HTTP codes for target group health check"
  type        = string
  default     = "200-399"
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to access ALB on port 80"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_name" {
  description = "Application Load Balancer name"
  type        = string
  default     = "springboot-app-alb"
}

variable "target_group_name" {
  description = "ALB target group name"
  type        = string
  default     = "springboot-app-tg"
}

variable "ec2_role_name" {
  description = "IAM role name for EC2"
  type        = string
  default     = "ec2-role"
}

variable "secrets_manager_prefix" {
  description = "Secrets Manager prefix used by the app"
  type        = string
  default     = "/springboot/dev/db"
}

variable "app_env" {
  description = "Spring profile to run"
  type        = string
  default     = "dev"
}

variable "ssm_parameter_prefix" {
  description = "SSM parameter path prefix used by the app"
  type        = string
  default     = "/springboot/dev/"
}

variable "project_name" {
  description = "Project prefix used in naming"
  type        = string
  default     = "springboot"
}

variable "s3_force_destroy" {
  description = "Whether Terraform can delete a non-empty bucket"
  type        = bool
  default     = false
}

variable "s3_default_prefix" {
  description = "Logical key prefix used by the app for regular uploads"
  type        = string
  default     = "uploads/"
}

variable "s3_tmp_prefix" {
  description = "Logical key prefix used for temporary objects"
  type        = string
  default     = "tmp/"
}

variable "s3_archive_prefix" {
  description = "Logical key prefix used for archive objects"
  type        = string
  default     = "archive/"
}

variable "s3_kms_key_alias" {
  description = "Alias for the KMS key used for SSE-KMS uploads"
  type        = string
  default     = "alias/springboot-s3-key"
}

variable "s3_kms_key_deletion_window_in_days" {
  description = "KMS key deletion window"
  type        = number
  default     = 7
}

variable "s3_lifecycle_tmp_expiration_days" {
  description = "Expire temp objects after this many days"
  type        = number
  default     = 7
}

variable "s3_lifecycle_archive_to_ia_days" {
  description = "Transition archive objects to STANDARD_IA after this many days"
  type        = number
  default     = 30
}

variable "s3_lifecycle_archive_to_glacier_ir_days" {
  description = "Transition archive objects to GLACIER_IR after this many days"
  type        = number
  default     = 90
}

variable "s3_lifecycle_archive_expiration_days" {
  description = "Expire archive objects after this many days"
  type        = number
  default     = 365
}

variable "s3_abort_incomplete_multipart_upload_days" {
  description = "Abort incomplete multipart uploads after this many days"
  type        = number
  default     = 7
}
