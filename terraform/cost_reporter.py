"""
AWS Cost Explorer Daily Report Lambda Function

This Lambda function provides daily cost reporting and analysis:
- Fetches daily costs from AWS Cost Explorer
- Analyzes spending trends and anomalies
- Publishes detailed reports via SNS
- Tracks costs by service and cost center

Environment Variables:
- SNS_TOPIC_ARN: SNS topic ARN for sending reports
- ENVIRONMENT: Environment name (staging, production)
- PROJECT_NAME: Project name for cost tracking
- MONTHLY_BUDGET: Monthly budget threshold in USD
"""

import json
import boto3
import os
from datetime import datetime, timedelta
from decimal import Decimal

# Initialize AWS clients
ce_client = boto3.client('ce')
sns_client = boto3.client('sns')
cloudwatch_client = boto3.client('cloudwatch')

# Environment variables
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'unknown')
PROJECT_NAME = os.environ.get('PROJECT_NAME', 'unknown')
MONTHLY_BUDGET = float(os.environ.get('MONTHLY_BUDGET', '100'))


def get_daily_costs(days_back=7):
    """
    Retrieve daily costs for the past N days from Cost Explorer.
    
    Args:
        days_back (int): Number of days to retrieve (default: 7)
        
    Returns:
        dict: Dictionary with dates as keys and costs as values
    """
    end_date = datetime.utcnow().date()
    start_date = end_date - timedelta(days=days_back)
    
    try:
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'SERVICE'
                }
            ]
        )
        
        daily_costs = {}
        for result in response['ResultsByTime']:
            date = result['TimePeriod']['Start']
            total_cost = 0.0
            
            for group in result['Groups']:
                cost = float(group['Metrics']['UnblendedCost']['Amount'])
                total_cost += cost
            
            daily_costs[date] = total_cost
        
        return daily_costs
    except Exception as e:
        print(f"Error retrieving daily costs: {str(e)}")
        return {}


def get_service_costs(days_back=7):
    """
    Retrieve costs broken down by AWS service.
    
    Args:
        days_back (int): Number of days to retrieve (default: 7)
        
    Returns:
        dict: Dictionary with service names as keys and costs as values
    """
    end_date = datetime.utcnow().date()
    start_date = end_date - timedelta(days=days_back)
    
    try:
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'SERVICE'
                }
            ]
        )
        
        service_costs = {}
        for result in response['ResultsByTime']:
            for group in result['Groups']:
                service = group['Keys'][0]
                cost = float(group['Metrics']['UnblendedCost']['Amount'])
                
                if service not in service_costs:
                    service_costs[service] = 0.0
                service_costs[service] += cost
        
        return service_costs
    except Exception as e:
        print(f"Error retrieving service costs: {str(e)}")
        return {}


def get_month_to_date_cost():
    """
    Calculate month-to-date costs and projected monthly cost.
    
    Returns:
        tuple: (mtd_cost, projected_cost, days_elapsed)
    """
    today = datetime.utcnow().date()
    month_start = today.replace(day=1)
    
    try:
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': month_start.strftime('%Y-%m-%d'),
                'End': today.strftime('%Y-%m-%d')
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost']
        )
        
        mtd_cost = 0.0
        for result in response['ResultsByTime']:
            cost = float(result['Total']['UnblendedCost']['Amount'])
            mtd_cost += cost
        
        days_elapsed = (today - month_start).days
        if days_elapsed > 0:
            daily_average = mtd_cost / days_elapsed
            projected_cost = daily_average * 30
        else:
            projected_cost = 0.0
        
        return mtd_cost, projected_cost, days_elapsed
    except Exception as e:
        print(f"Error retrieving MTD cost: {str(e)}")
        return 0.0, 0.0, 0


def publish_report(report_content):
    """
    Publish cost report to SNS topic.
    
    Args:
        report_content (str): The report content to publish
    """
    if not SNS_TOPIC_ARN:
        print("SNS_TOPIC_ARN not configured, skipping report publication")
        return
    
    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f'Daily Cost Report - {PROJECT_NAME} ({ENVIRONMENT})',
            Message=report_content
        )
        print("Report published to SNS successfully")
    except Exception as e:
        print(f"Error publishing report to SNS: {str(e)}")


def generate_report():
    """
    Generate comprehensive daily cost report.
    
    Returns:
        str: Formatted cost report
    """
    # Retrieve cost data
    daily_costs = get_daily_costs(days_back=7)
    service_costs = get_service_costs(days_back=7)
    mtd_cost, projected_cost, days_elapsed = get_month_to_date_cost()
    
    # Sort services by cost (descending)
    sorted_services = sorted(service_costs.items(), key=lambda x: x[1], reverse=True)
    top_services = sorted_services[:5]  # Top 5 services
    
    # Calculate metrics
    budget_percentage = (mtd_cost / MONTHLY_BUDGET * 100) if MONTHLY_BUDGET > 0 else 0
    budget_remaining = max(0, MONTHLY_BUDGET - projected_cost)
    budget_status = "🔴 OVER BUDGET" if projected_cost > MONTHLY_BUDGET else "🟢 WITHIN BUDGET"
    
    # Build report
    report = f"""
================================================================================
                    AWS COST EXPLORER DAILY REPORT
================================================================================

Project:        {PROJECT_NAME}
Environment:    {ENVIRONMENT}
Report Date:    {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}

================================================================================
                          COST SUMMARY
================================================================================

Month-to-Date Cost:         ${mtd_cost:,.2f}
Days in Month (Elapsed):    {days_elapsed} days
Monthly Budget:             ${MONTHLY_BUDGET:,.2f}
Budget Usage:               {budget_percentage:.1f}%
Projected Monthly Cost:     ${projected_cost:,.2f}
Budget Status:              {budget_status}
Projected Budget Remaining: ${budget_remaining:,.2f}

================================================================================
                        TOP 5 SERVICES BY COST
================================================================================
"""
    
    for i, (service, cost) in enumerate(top_services, 1):
        pct = (cost / mtd_cost * 100) if mtd_cost > 0 else 0
        report += f"{i}. {service:30s} ${cost:>10,.2f} ({pct:>5.1f}%)\n"
    
    report += f"""
================================================================================
                          DAILY COST TREND (7 days)
================================================================================
"""
    
    for date in sorted(daily_costs.keys()):
        cost = daily_costs[date]
        bar_length = int(cost / 5)  # Scale for visualization
        bar = '█' * bar_length
        report += f"{date}   ${cost:>8,.2f}   {bar}\n"
    
    report += f"""
================================================================================
                            RECOMMENDATIONS
================================================================================

"""
    
    # Generate recommendations
    if projected_cost > MONTHLY_BUDGET:
        report += f"⚠️  ALERT: Projected monthly cost (${projected_cost:,.2f}) exceeds budget (${MONTHLY_BUDGET:,.2f})\n"
        report += f"   Current overage: ${projected_cost - MONTHLY_BUDGET:,.2f}\n"
        report += "   Consider: Reviewing unused resources, rightsizing instances, or enabling auto-shutdown.\n\n"
    
    if len(sorted_services) > 0:
        top_service, top_cost = sorted_services[0]
        pct = (top_cost / mtd_cost * 100) if mtd_cost > 0 else 0
        report += f"📊 {top_service} accounts for {pct:.1f}% of costs.\n"
        report += f"   Review {top_service} usage for optimization opportunities.\n\n"
    
    # Check for daily growth
    if len(daily_costs) > 1:
        dates = sorted(daily_costs.keys())
        today_cost = daily_costs[dates[-1]]
        yesterday_cost = daily_costs[dates[-2]]
        if today_cost > yesterday_cost * 1.2:
            growth = ((today_cost - yesterday_cost) / yesterday_cost * 100)
            report += f"⬆️  Daily cost increased by {growth:.1f}% - investigate recent changes.\n\n"
    
    report += f"""
================================================================================
                          TAGGING STRATEGY
================================================================================

Cost allocation and governance enabled with the following tags:
- Environment:      Environment name (staging, production)
- Project:          Project identifier ({PROJECT_NAME})
- CostCenter:       Cost center for billing (configured per environment)
- Owner:            Team responsible for resources
- BillingGroup:     Billing group (dev/prod split)
- Application:      Application name for cost allocation

Review tags in AWS Cost Explorer to validate proper cost allocation.

================================================================================
                         MORE INFORMATION
================================================================================

AWS Cost Explorer:     https://console.aws.amazon.com/cost-management/home
CloudWatch Dashboard:  {PROJECT_NAME}-{ENVIRONMENT}-cost-overview
AWS Budgets:           https://console.aws.amazon.com/billing/home#/budgets

For questions or alerts, contact the DevOps team.

================================================================================
"""
    
    return report


def lambda_handler(event, context):
    """
    Lambda handler function for daily cost reporting.
    
    Args:
        event (dict): Lambda event payload
        context (object): Lambda context object
        
    Returns:
        dict: Lambda response
    """
    try:
        print(f"Starting daily cost report for {PROJECT_NAME} ({ENVIRONMENT})")
        
        # Generate report
        report = generate_report()
        
        # Publish to SNS
        publish_report(report)
        
        # Log report to CloudWatch
        print(report)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Daily cost report generated successfully',
                'project': PROJECT_NAME,
                'environment': ENVIRONMENT
            })
        }
    except Exception as e:
        error_msg = f"Error generating daily cost report: {str(e)}"
        print(error_msg)
        
        # Publish error notification
        if SNS_TOPIC_ARN:
            try:
                sns_client.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Subject=f'ERROR: Daily Cost Report - {PROJECT_NAME} ({ENVIRONMENT})',
                    Message=error_msg
                )
            except Exception as sns_error:
                print(f"Error publishing error notification: {str(sns_error)}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error generating daily cost report',
                'error': str(e)
            })
        }


if __name__ == "__main__":
    # Local testing
    os.environ['SNS_TOPIC_ARN'] = 'arn:aws:sns:us-east-1:123456789012:test-topic'
    os.environ['ENVIRONMENT'] = 'staging'
    os.environ['PROJECT_NAME'] = 'test'
    os.environ['MONTHLY_BUDGET'] = '100'
    
    report = generate_report()
    print(report)
