# --- variables.tf ---

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "route53_zone_id" {
  description = "The Route 53 Hosted Zone ID for domain DNS validation"
  type        = string
}

# ... only variable "..." {} blocks belong in this file ...
