# ============================================================================
# TERRAFORM VARIABLES DEFINITION
# ============================================================================

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================
variable "environment" {
  description = "Environment name (staging/production)"
  type        = string
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be 'staging' or 'production'."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# VPC & NETWORKING
# ============================================================================
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

# ============================================================================
# SECURITY
# ============================================================================
variable "allow_http_cidrs" {
  description = "CIDR blocks allowed to access ALB on HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allow_https_cidrs" {
  description = "CIDR blocks allowed to access ALB on HTTPS"
  type        = list(string)
  default     = []
}

# ============================================================================
# RDS DATABASE
# ============================================================================
variable "db_engine" {
  description = "Database engine (postgres/mysql)"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "14"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t2.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "backup_retention_period" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying database"
  type        = bool
  default     = false
}

# ============================================================================
# ECS FARGATE
# ============================================================================
variable "container_image" {
  description = "Docker image URI (full ECR path, e.g., ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/tic-tac-toe-app:latest)"
  type        = string
  default     = "tic-tac-toe-app:latest"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 5000
}

variable "task_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, etc.)"
  type        = number
  default     = 256
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Fargate task memory in MB (512, 1024, 2048, etc.)"
  type        = number
  default     = 512
  validation {
    condition     = contains([512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192], var.task_memory)
    error_message = "Task memory must be a valid Fargate memory value."
  }
}

variable "desired_task_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "min_task_count" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "max_task_count" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "autoscaling_enabled" {
  description = "Enable auto-scaling for ECS tasks"
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = false
}

# ============================================================================
# LOGGING & MONITORING
# ============================================================================
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = false
}

# ============================================================================
# EC2 KEY PAIR
# ============================================================================
variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = ""
}

# ============================================================================
# OPTION E: COST GOVERNANCE & TAGGING
# ============================================================================

variable "cost_center" {
  description = "Cost center code for billing and allocation"
  type        = string
  default     = "engineering"
}

variable "owner" {
  description = "Owner/team responsible for resources"
  type        = string
  default     = "DevOps Team"
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "monthly_budget" {
  description = "Monthly budget limit in USD for this environment"
  type        = number
  default     = 100
  validation {
    condition     = var.monthly_budget > 0
    error_message = "Monthly budget must be greater than 0."
  }
}

variable "alert_email" {
  description = "Email address for cost budget alerts (leave empty to disable)"
  type        = string
  default     = ""
}

variable "enable_cost_governance" {
  description = "Enable AWS Budgets, SNS alerts, and cost monitoring"
  type        = bool
  default     = true
}

variable "cost_anomaly_threshold_percentage" {
  description = "Daily cost threshold as percentage of monthly budget to trigger alert"
  type        = number
  default     = 50
  validation {
    condition     = var.cost_anomaly_threshold_percentage > 0 && var.cost_anomaly_threshold_percentage < 200
    error_message = "Threshold must be between 0 and 200 percent."
  }
}




