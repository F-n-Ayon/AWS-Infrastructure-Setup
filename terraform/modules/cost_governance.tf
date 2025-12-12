# ============================================================================
#  COST OPTIMIZATION & GOVERNANCE MODULE
# ============================================================================
# This module adds comprehensive cost monitoring, budgets, and governance to
# the existing Option A infrastructure.
#
# Features:
# - AWS Budgets with thresholds (80%, 100%, 120%)
# - SNS notifications for budget alerts
# - Enhanced tagging strategy
# - Cost allocation tags
# - CloudWatch metrics for cost tracking
# ============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# SNS TOPIC FOR COST ALERTS
# ============================================================================

resource "aws_sns_topic" "cost_alerts" {
  name              = "${var.project_name}-${var.environment}-cost-alerts"
  display_name      = "Cost Alerts for ${var.project_name}-${var.environment}"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name    = "${var.project_name}-${var.environment}-cost-alerts"
    Purpose = "Cost Governance"
  }
}

resource "aws_sns_topic_policy" "cost_alerts" {
  arn = aws_sns_topic.cost_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.cost_alerts.arn
      }
    ]
  })
}

# ============================================================================
# SNS EMAIL SUBSCRIPTION (User configurable)
# ============================================================================

resource "aws_sns_topic_subscription" "cost_alerts_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ============================================================================
# AWS BUDGET FOR MONTHLY SPENDING (TOTAL)
# ============================================================================

resource "aws_budgets_budget" "monthly_total" {
  name              = "${var.project_name}-${var.environment}-monthly-total"
  budget_type       = "COST"
  limit_unit        = "USD"
  limit_amount      = var.monthly_budget
  time_period_start = "2025-01-01"
  time_period_end   = "2099-12-31"
  time_unit         = "MONTHLY"

  cost_filters = {
    Environment = [var.environment]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_trigger_delay = 0

    subscriber_email_addresses = var.alert_email != "" ? [var.alert_email] : []
    subscriber_sns_topic_arns  = [aws_sns_topic.cost_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_trigger_delay = 0

    subscriber_email_addresses = var.alert_email != "" ? [var.alert_email] : []
    subscriber_sns_topic_arns  = [aws_sns_topic.cost_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 120
    threshold_type             = "PERCENTAGE"
    notification_trigger_delay = 0

    subscriber_email_addresses = var.alert_email != "" ? [var.alert_email] : []
    subscriber_sns_topic_arns  = [aws_sns_topic.cost_alerts.arn]
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-monthly-budget"
    Purpose = "Cost Governance"
  }
}

# ============================================================================
# AWS BUDGET FOR SERVICE-LEVEL COSTS
# ============================================================================

resource "aws_budgets_budget" "service_costs" {
  name              = "${var.project_name}-${var.environment}-service-costs"
  budget_type       = "COST"
  limit_unit        = "USD"
  limit_amount      = var.monthly_budget * 0.9 # 90% of total budget
  time_period_start = "2025-01-01"
  time_period_end   = "2099-12-31"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_trigger_delay = 0

    subscriber_email_addresses = var.alert_email != "" ? [var.alert_email] : []
    subscriber_sns_topic_arns  = [aws_sns_topic.cost_alerts.arn]
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-service-budget"
    Purpose = "Cost Governance"
  }
}

# ============================================================================
# CLOUDWATCH LOG GROUP FOR COST METRICS (Custom Metrics)
# ============================================================================

resource "aws_cloudwatch_log_group" "cost_metrics" {
  name              = "/aws/cost/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name    = "${var.project_name}-${var.environment}-cost-metrics"
    Purpose = "Cost Tracking"
  }
}

# ============================================================================
# CLOUDWATCH DASHBOARD FOR COST VISUALIZATION
# ============================================================================

resource "aws_cloudwatch_dashboard" "cost_overview" {
  dashboard_name = "${var.project_name}-${var.environment}-cost-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", { stat = "Maximum" }]
          ]
          period = 86400
          stat   = "Maximum"
          region = var.aws_region
          title  = "Estimated Monthly Charges"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "log"
        properties = {
          query  = "fields @timestamp, @message | filter @message like /cost/ | stats sum(cost) by service"
          region = var.aws_region
          title  = "Cost by Service (from logs)"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "EstimatedCharges", { stat = "Sum" }],
            ["AWS/RDS", "EstimatedCharges", { stat = "Sum" }],
            ["AWS/NatGateway", "EstimatedCharges", { stat = "Sum" }]
          ]
          period = 86400
          stat   = "Sum"
          region = var.aws_region
          title  = "Estimated Charges by Service"
        }
      }
    ]
  })
}

# ============================================================================
# CLOUDWATCH METRIC ALARM FOR COST ANOMALY
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "cost_anomaly" {
  alarm_name          = "${var.project_name}-${var.environment}-cost-anomaly"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = var.monthly_budget * 0.5 # Alert if >50% of budget in one day
  alarm_description   = "Alert when daily estimated charges exceed 50% of monthly budget"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-cost-anomaly-alarm"
    Purpose = "Cost Governance"
  }
}

# ============================================================================
# LAMBDA FUNCTION FOR COST ANALYSIS & REPORTING (Optional)
# ============================================================================

resource "aws_iam_role" "cost_lambda_role" {
  name = "${var.project_name}-${var.environment}-cost-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-${var.environment}-cost-lambda-role"
    Purpose = "Cost Governance"
  }
}

resource "aws_iam_role_policy" "cost_lambda_policy" {
  name = "${var.project_name}-${var.environment}-cost-lambda-policy"
  role = aws_iam_role.cost_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetCostForecast",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "cost_reporter" {
  filename         = "cost_reporter.zip"
  function_name    = "${var.project_name}-${var.environment}-cost-reporter"
  role             = aws_iam_role.cost_lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("cost_reporter.zip")
  runtime          = "python3.11"
  timeout          = 60

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.cost_alerts.arn
      ENVIRONMENT   = var.environment
      PROJECT_NAME  = var.project_name
    }
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-cost-reporter"
    Purpose = "Cost Governance"
  }

  depends_on = [aws_iam_role_policy.cost_lambda_policy]
}

# ============================================================================
# EVENTBRIDGE RULE TO TRIGGER COST REPORTER DAILY
# ============================================================================

resource "aws_cloudwatch_event_rule" "daily_cost_report" {
  name                = "${var.project_name}-${var.environment}-daily-cost-report"
  description         = "Trigger daily cost analysis"
  schedule_expression = "cron(0 9 * * ? *)" # 9 AM UTC daily

  tags = {
    Name    = "${var.project_name}-${var.environment}-daily-cost-report"
    Purpose = "Cost Governance"
  }
}

resource "aws_cloudwatch_event_target" "cost_reporter" {
  rule      = aws_cloudwatch_event_rule.daily_cost_report.name
  target_id = "CostReporterFunction"
  arn       = aws_lambda_function.cost_reporter.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_reporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cost_report.arn
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "cost_alerts_topic_arn" {
  description = "SNS Topic ARN for cost alerts"
  value       = aws_sns_topic.cost_alerts.arn
}

output "cost_budget_name" {
  description = "AWS Budget name"
  value       = aws_budgets_budget.monthly_total.name
}

output "cost_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.cost_overview.dashboard_name}"
}

output "cost_reporter_function_name" {
  description = "Lambda function name for cost reporting"
  value       = aws_lambda_function.cost_reporter.function_name
}
