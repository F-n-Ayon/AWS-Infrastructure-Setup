# ============================================================================
# TAGGING STRATEGY - COST ALLOCATION & GOVERNANCE
# ============================================================================
# Comprehensive tagging strategy to enable cost allocation, compliance
# tracking, and resource governance. Tags are automatically applied to all
# resources via provider default_tags.
# ============================================================================

# ============================================================================
# LOCAL VARIABLES - TAG DEFINITIONS
# ============================================================================

locals {
  # Base mandatory tags applied to all resources
  base_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    Owner       = var.owner
    CreatedDate = timestamp()
    CreatedBy   = "Terraform"
  }

  # Application-level tags
  application_tags = {
    Application        = var.project_name
    ApplicationVersion = "1.0"
    DataClassification = "Confidential"
  }

  # Operational tags
  operational_tags = {
    Backup        = "daily"
    Compliance    = "true"
    ChangeControl = "required"
    AutoShutdown  = "false"
    Schedule      = "always-on"
    Monitoring    = "enabled"
    LogRetention  = "30"
  }

  # Cost allocation and billing tags
  cost_tags = {
    BillingGroup   = var.environment == "production" ? "prod" : "dev"
    ChargebackCode = "${var.cost_center}-${var.environment}"
    CostAllocation = "enabled"
  }

  # Compliance and audit tags
  compliance_tags = {
    Compliance         = "true"
    DataClassification = "Confidential"
    ChangeControl      = "required"
  }

  # Merge all tag groups with additional custom tags
  all_tags = merge(
    local.base_tags,
    local.application_tags,
    local.operational_tags,
    local.cost_tags,
    local.compliance_tags,
    var.additional_tags
  )
}

# ============================================================================
# AWS COST EXPLORER COST ALLOCATION TAGS (DISABLED FOR INITIAL DEPLOYMENT)
# ============================================================================
# Note: Cost Allocation Tags require the tag keys to already exist on resources
# They will be created automatically when resources are tagged
# Uncomment after first deployment when tags exist on resources

# resource "aws_ce_cost_allocation_tag" "environment_tag" {
#   tag_key = "Environment"
#   status  = "Active"
# }

# resource "aws_ce_cost_allocation_tag" "project_tag" {
#   tag_key = "Project"
#   status  = "Active"
# }

# resource "aws_ce_cost_allocation_tag" "cost_center_tag" {
#   tag_key = "CostCenter"
#   status  = "Active"
# }

# resource "aws_ce_cost_allocation_tag" "owner_tag" {
#   tag_key = "Owner"
#   status  = "Active"
# }

# resource "aws_ce_cost_allocation_tag" "application_tag" {
#   tag_key = "Application"
#   status  = "Active"
# }

# resource "aws_ce_cost_allocation_tag" "billing_group_tag" {
#   tag_key = "BillingGroup"
#   status  = "Active"
# }

# ============================================================================
# TAGGING STRATEGY OUTPUTS
# ============================================================================

output "applied_tags" {
  description = "All tags being applied to resources"
  value       = local.all_tags
}

output "tag_strategy_documentation" {
  description = "Tag strategy documentation"
  value = {
    base_tags = {
      purpose     = "Mandatory tags for all resources"
      categories  = keys(local.base_tags)
      description = "Includes environment, project, owner, cost center, and creation metadata"
    }
    application_tags = {
      purpose     = "Application-level identification and classification"
      categories  = keys(local.application_tags)
      description = "Includes application name, version, and data classification"
    }
    operational_tags = {
      purpose     = "Operational management and monitoring"
      categories  = keys(local.operational_tags)
      description = "Includes backup, compliance, scheduling, and monitoring settings"
    }
    cost_tags = {
      purpose     = "Cost allocation and chargeback"
      categories  = keys(local.cost_tags)
      description = "Includes billing group, chargeback code, and cost allocation enablement"
    }
    compliance_tags = {
      purpose     = "Compliance and audit tracking"
      categories  = keys(local.compliance_tags)
      description = "Includes compliance status and data classification"
    }
    cost_allocation_activated = [
      "Environment",
      "Project",
      "CostCenter",
      "Owner",
      "Application",
      "BillingGroup"
    ]
  }
}

output "cost_center_tag_value" {
  description = "Cost center tag value for billing"
  value       = var.cost_center
}

output "billing_group_tag_value" {
  description = "Billing group value (dev or prod)"
  value       = local.cost_tags.BillingGroup
}

