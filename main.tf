# ==============================================================================
# Providers & Global Configuration
# ==============================================================================

# Default provider for primary region
provider "aws" {
  region = var.aws_region
}

# Secondary provider explicitly for CloudFront ACM certificates
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ==============================================================================
# Data Sources
# ==============================================================================

# Look up existing ACM certificate in us-east-1 for CloudFront
data "aws_acm_certificate" "existing_cert" {
  provider    = aws.us_east_1
  domain      = "evergreenlifeagency.com"
  statuses    = ["ISSUED"]
  most_recent = true
}

# Data Source for Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==============================================================================
# Infrastructure Modules
# ==============================================================================

# 1. Network Tier
module "network" {
  source = "../../../modules/network"

  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_count  = 2
  private_subnet_count = 2
}

# 2. Security Groups Tier
module "security_groups" {
  source = "../../../modules/security_groups"
  vpc_id = module.network.vpc_id
}

# 3. Application Load Balancer Tier
module "alb" {
  source = "../../../modules/alb"

  environment           = "dev"
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  domain_name           = "*.evergreenlifeagency.com"
  app_port              = 80
}

# 4. CloudFront CDN Tier
module "cdn" {
  source              = "../../../modules/cloudfront"
  acm_certificate_arn = data.aws_acm_certificate.existing_cert.arn
  environment         = "dev"
  domain_name         = "utc.evergreenlifeagency.com"
  hosted_zone_name    = "evergreenlifeagency.com" # Fixed: Apex zone name without wildcard
  hosted_zone_id      = "Z066892214C0IZTRGD4Q3"
  alb_dns_name        = module.alb.alb_dns_name
}

# 5. S3 App Storage Tier
module "s3" {
  source = "../../../modules/s3-bucket"

  environment       = "dev"
  bucket_name       = "my-app-assets-prod-unique-bucket-name"
  enable_versioning = true
  force_destroy     = false
}

# 6. Secrets Manager Tier
module "secrets" {
  source = "../../../modules/secrets"

  environment = "dev"
  db_username = "dbadmin"
}

# 7. IAM Module Tier
module "iam" {
  source = "../../../modules/iam"

  environment   = "dev"
  s3_bucket_arn = module.s3.bucket_arn
  db_secret_arn = module.secrets.secret_arn
}

# 8. Auto Scaling Group Tier
module "asg" {
  source = "../../../modules/Auto-scaling-group"

  environment              = "dev"
  ami_id                   = data.aws_ami.amazon_linux_2023.id
  instance_type            = "t3.micro"
  app_sg_id                = module.security_groups.app_sg_id
  private_subnet_ids       = module.network.private_subnet_ids
  target_group_arn         = module.alb.target_group_arn
  iam_instance_profile_arn = module.iam.instance_profile_arn

  min_size         = 2
  max_size         = 6
  desired_capacity = 2

  # Raw user data.
  # The ASG module will Base64 encode this before sending it to EC2.
  user_data = <<-EOF
    #!/bin/bash

    exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

    echo "Starting EC2 user-data..."

    # Update packages
    dnf update -y

    # Install Nginx
    dnf install -y nginx

    # Create application home page
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head>
        <title>Evergreen Life Agency</title>
    </head>
    <body>
        <h1>Evergreen Life Agency - Server Active</h1>
        <p>Application server is running successfully.</p>
    </body>
    </html>
    HTML

    # Enable and start Nginx
    systemctl enable nginx
    systemctl restart nginx

    echo "User-data completed successfully."
  EOF
}

# 9. Database Tier (RDS PostgreSQL)
module "rds" {
  source = "../../../modules/rds"

  environment    = "dev"
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t4g.micro"

  db_name     = "appdb"
  db_username = "dbadmin"
  db_password = "SuperSecretPass123!"

  private_subnet_ids = module.network.private_subnet_ids
  db_sg_id           = module.security_groups.db_sg_id

  multi_az                = true
  backup_retention_period = 1
  backup_window           = "02:00-03:00"
  maintenance_window      = "Sun:04:00-Sun:05:00"
}

# 10. EFS Shared Storage Tier
module "efs" {
  source = "../../../modules/elastic-file"

  environment        = "dev"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  app_sg_id          = module.security_groups.app_sg_id
  transition_to_ia   = "AFTER_30_DAYS"
}

# 11. Monitoring & Alerting Tier
module "monitoring" {
  source = "../../../modules/monitoring"

  environment           = "dev"
  alert_email           = "oswald24ck@gmail.com"
  asg_name              = module.asg.asg_name
  alb_arn_suffix        = module.alb.alb_arn_suffix
  rds_instance_id       = module.rds.db_instance_id
  log_retention_in_days = 30
}

# ==============================================================================
# Outputs
# ==============================================================================

output "dev_vpc_id" {
  value = module.network.vpc_id
}

output "dev_public_subnets" {
  value = module.network.public_subnet_ids
}

output "dev_private_subnets" {
  value = module.network.private_subnet_ids
}