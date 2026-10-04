# utc-app-terraform

# utc-app-terraform

# Secure AWS 3-Tier Web Architecture with Terraform

This repository provisions a highly available, secure, and auto-scaling 3-Tier infrastructure on AWS using modular Terraform.

## Architecture Highlights
<img width="1408" height="768" alt="architecture-diagram" src="https://github.com/user-attachments/assets/86af8db7-94b2-4e2c-b18e-202992a16118" />


* **Web/Presentation Tier:** Internet-facing Application Load Balancer (ALB) across multi-AZ public subnets.
* **Application Tier:** Auto Scaling Group (ASG) of EC2 instances in private subnets with auto-mounted AWS EFS for shared filesystem storage and S3 integration for object storage.
* **Database Tier:** Amazon RDS instance in private database subnets with automated credential rotation integration.
* **Security & Governance:**
  * Zero inbound SSH (Managed via AWS Systems Manager Session Manager).
  * RDS credentials stored in **AWS Secrets Manager** (dynamically generated).
  * Least-privilege IAM instance roles (S3, Secrets Manager, CloudWatch Agent, SSM).
  * Encrypted EFS, S3 (AES256), and CloudWatch Logs.
* **Monitoring & Alerts:** CloudWatch alarms monitoring ASG CPU, ALB 5xx rates, and RDS storage/CPU, publishing to an SNS email topic.

# Directory Structure

utc-app-terraform/
├── main.tf                   # Root module orchestration
├── variables.tf              # Root input variable declarations
├── outputs.tf                # Root deployment outputs
├── terraform.tfvars.example  # Input values template
├── README.md                 # Architecture & operational documentation
└── modules/
    ├── alb/           # VPC, Subnets, IGW, NAT Gateways, Route Tables
    ├── Auto-scaling-group    # Launch Template (with EFS mount user_data) & Auto Scaling Group
    ├── cloudfront            # CloudFront Distribution & Route 53 DNS Records
    ├── elastic-file          # Elastic File System & Private Mount Targets
    ├── iam/                  # EC2 Instance Profile (S3, SecretsManager, SSM, CloudWatch)
    ├── monitoring/           # CloudWatch Log Groups, Alarms, and SNS Email Alerts
    ├── rds/                  # Multi-AZ DB Subnet Group & PostgreSQL/MySQL RDS
    ├── s3-bucket/            # Application S3 Bucket (SSE-S3, Versioned, Block Public Access)
    ├── secrets/              # Secrets Manager & Random Password Generation
    ├── security_groups/      # Layered SGs (ALB, App EC2, RDS, EFS)
    └──  alb/                  # Application Load Balancer & Target Groups
                  
    
---

## Deployment Steps

### 1. Prerequisites
* Install [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.5.0)
* Install [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and configure credentials:
  ```bash
  aws configure

  Visual Verification & Deployments
# 1. Terraform Deployment Success
<img width="1295" height="1029" alt="terraform-apply-succes" src="https://github.com/user-attachments/assets/8a2d8db6-6254-46e3-878a-65d40ab48457" />

# 2. Application Load Balancer & Target Group
<img width="1520" height="737" alt="alb healthy target" src="https://github.com/user-attachments/assets/3fcf90cb-f189-4d92-ba62-766550293c3e" />

# 3. CloudFront Global Distribution
<img width="1561" height="724" alt="cloudfront distribution" src="https://github.com/user-attachments/assets/23cd761b-af64-4647-b38f-08dc6525f084" />

# 4. Active Live Website
<img width="1188" height="852" alt="live website https" src="https://github.com/user-attachments/assets/85d1c43f-9bf1-460b-97f8-dcb72de7dcf6" />

# 5. Multi-AZ RDS Database Instance
<img width="1556" height="727" alt="rds instance status" src="https://github.com/user-attachments/assets/a6b4c346-f13e-476f-a520-d210075def8c" />

# 6. CloudWatch Alarms & SNS Notification
<img width="1582" height="727" alt="cloudwatch" src="https://github.com/user-attachments/assets/067a9dee-40f0-47bd-98fc-953a2ebe25af" />


