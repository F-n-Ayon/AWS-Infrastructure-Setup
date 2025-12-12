# ============================================================================
# COST OPTIMIZATION & GOVERNANCE RESOURCES
# ============================================================================
# This configuration adds comprehensive cost monitoring, budgets, and 
# governance to the existing Option A infrastructure.
#
# Features:
# - AWS Budgets with thresholds (80%, 100%, 120%)
# - SNS notifications for budget alerts
# - Enhanced tagging strategy
# - Cost allocation tags
# - CloudWatch metrics for cost tracking
# - Lambda-based daily cost reporting
# ============================================================================

# ============================================================================
# SNS TOPIC FOR COST ALERTS
# ============================================================================

resource "aws_sns_topic" "cost_alerts" {
  count             = var.enable_cost_governance ? 1 : 0
  name              = "${var.project_name}-${var.environment}-cost-alerts"
  display_name      = "Cost Alerts for ${var.project_name}-${var.environment}"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name    = "${var.project_name}-${var.environment}-cost-alerts"
    Purpose = "Cost Governance"
  }
}

resource "aws_sns_topic_policy" "cost_alerts" {
  count = var.enable_cost_governance ? 1 : 0
  arn   = aws_sns_topic.cost_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.cost_alerts[0].arn
      }
    ]
  })
}

# ============================================================================
# SNS EMAIL SUBSCRIPTION (User configurable)
# ============================================================================

resource "aws_sns_topic_subscription" "cost_alerts_email" {
  count     = var.enable_cost_governance && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.cost_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ============================================================================
# AWS BUDGET FOR MONTHLY SPENDING (TOTAL)
# ============================================================================

resource "aws_budgets_budget" "monthly_total" {
  count             = var.enable_cost_governance ? 1 : 0
  name              = "${var.project_name}-${var.environment}-monthly-total"
  budget_type       = "COST"
  limit_unit        = "USD"
  limit_amount      = var.monthly_budget
  time_period_start = "2025-01-01_00:00"
  time_period_end   = "2027-12-31_23:59"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "FORECASTED"
    threshold           = 80
    threshold_type      = "PERCENTAGE"

    subscriber_email_addresses = var.alert_email != "" ? [var.alert_email] : []
    subscriber_sns_topic_arns  = [aws_sns_topic.cost_alerts[0].arn]
  }

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "FORECASTED"
    threshold           = 100
    threshold_type      = "PERCENTAGE"

    subscriber_email_addresses = var.alert_email != "" ? [var.alert_email] : []
    subscriber_sns_topic_arns  = [aws_sns_topic.cost_alerts[0].arn]
  }

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "FORECASTED"
    threshold           = 120
    threshold_type      = "PERCENTAGE"

    subscriber_email_addresses = var.alert_email != "" ? [var.alert_email] : []
    subscriber_sns_topic_arns  = [aws_sns_topic.cost_alerts[0].arn]
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-monthly-budget"
    Purpose = "Cost Governance"
  }

  depends_on = [aws_sns_topic_policy.cost_alerts]
}

# ============================================================================
# AWS BUDGET FOR SERVICE-LEVEL COSTS
# ============================================================================

resource "aws_budgets_budget" "service_costs" {
  count             = var.enable_cost_governance ? 1 : 0
  name              = "${var.project_name}-${var.environment}-service-costs"
  budget_type       = "COST"
  limit_unit        = "USD"
  limit_amount      = var.monthly_budget * 0.9 # 90% of total budget
  time_period_start = "2025-01-01_00:00"
  time_period_end   = "2027-12-31_23:59"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "FORECASTED"
    threshold           = 100
    threshold_type      = "PERCENTAGE"

    subscriber_email_addresses = var.alert_email != "" ? [var.alert_email] : []
    subscriber_sns_topic_arns  = [aws_sns_topic.cost_alerts[0].arn]
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-service-budget"
    Purpose = "Cost Governance"
  }

  depends_on = [aws_sns_topic_policy.cost_alerts]
}

# ============================================================================
# CLOUDWATCH LOG GROUP FOR COST METRICS (Custom Metrics)
# ============================================================================

resource "aws_cloudwatch_log_group" "cost_metrics" {
  count             = var.enable_cost_governance ? 1 : 0
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
  count          = var.enable_cost_governance ? 1 : 0
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
  count               = var.enable_cost_governance ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-cost-anomaly"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = var.monthly_budget * (var.cost_anomaly_threshold_percentage / 100)
  alarm_description   = "Alert when daily estimated charges exceed ${var.cost_anomaly_threshold_percentage}% of monthly budget"
  alarm_actions       = var.enable_cost_governance ? [aws_sns_topic.cost_alerts[0].arn] : []

  dimensions = {
    Currency = "USD"
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-cost-anomaly-alarm"
    Purpose = "Cost Governance"
  }
}

# ============================================================================
# LAMBDA IAM ROLE FOR COST ANALYSIS & REPORTING
# ============================================================================

resource "aws_iam_role" "cost_lambda_role" {
  count = var.enable_cost_governance ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cost-lambda-role"

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
  count = var.enable_cost_governance ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cost-lambda-policy"
  role  = aws_iam_role.cost_lambda_role[0].id

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
          "sns:Publish",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# LAMBDA FUNCTION FOR COST ANALYSIS & REPORTING
# ============================================================================

resource "aws_lambda_function" "cost_reporter" {
  count            = var.enable_cost_governance ? 1 : 0
  filename         = "${path.module}/cost_reporter.zip"
  function_name    = "${var.project_name}-${var.environment}-cost-reporter"
  role             = aws_iam_role.cost_lambda_role[0].arn
  handler          = "cost_reporter.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/cost_reporter.zip")
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      SNS_TOPIC_ARN  = aws_sns_topic.cost_alerts[0].arn
      ENVIRONMENT    = var.environment
      PROJECT_NAME   = var.project_name
      MONTHLY_BUDGET = var.monthly_budget
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
  count               = var.enable_cost_governance ? 1 : 0
  name                = "${var.project_name}-${var.environment}-daily-cost-report"
  description         = "Trigger daily cost analysis and reporting"
  schedule_expression = "cron(0 9 * * ? *)" # 9 AM UTC daily

  tags = {
    Name    = "${var.project_name}-${var.environment}-daily-cost-report"
    Purpose = "Cost Governance"
  }
}

resource "aws_cloudwatch_event_target" "cost_reporter" {
  count     = var.enable_cost_governance ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_cost_report[0].name
  target_id = "CostReporterFunction"
  arn       = aws_lambda_function.cost_reporter[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count         = var.enable_cost_governance ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_reporter[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cost_report[0].arn
}

# ============================================================================
# COST GOVERNANCE OUTPUTS
# ============================================================================

output "cost_governance_enabled" {
  description = "Whether cost governance is enabled"
  value       = var.enable_cost_governance
}

output "cost_alerts_topic_arn" {
  description = "SNS Topic ARN for cost alerts"
  value       = var.enable_cost_governance ? aws_sns_topic.cost_alerts[0].arn : "Not enabled"
}

output "cost_budget_name" {
  description = "AWS Budget name"
  value       = var.enable_cost_governance ? aws_budgets_budget.monthly_total[0].name : "Not enabled"
}

output "cost_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = var.enable_cost_governance ? "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.cost_overview[0].dashboard_name}" : "Not enabled"
}

output "cost_reporter_function_name" {
  description = "Lambda function name for cost reporting"
  value       = var.enable_cost_governance ? aws_lambda_function.cost_reporter[0].function_name : "Not enabled"
}

