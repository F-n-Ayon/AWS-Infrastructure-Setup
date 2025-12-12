# AWS Infrastructure Setup: 

**Status**: ✅ READY FOR DEPLOYMENT  
**Cost**: ~$51/month ($50 + Cost Optimization & Governance: $1.30)  
**Time to Deploy**: 40 minutes  

---

## 📚 DOCUMENTATION (3 Essential Files)

### 1. **QUICK_START.md** ⚡ (5 minutes)
**Best for**: Fast deployment without deep understanding
- Edit 2 files
- Run 3 terraform commands
- Test application
- **Start here if you just want to deploy**

### 2. **COMBINED_SUMMARY.md** 📊 (15-30 minutes)
**Best for**: Understanding architecture and cost
- Executive summary
- Architecture overview with diagram
- Cost breakdown ($51/month)
- What's included (files & components)
- Key features overview
- Common issues & solutions
- **Start here if you want full context before deploying**

### 3. **DEPLOYMENT_CHECKLIST.md** ✅ (During deployment - 1 hour)
**Best for**: Step-by-step guidance during actual deployment
- Pre-deployment verification
- Configuration instructions (what to edit where)
- Deployment commands
- Post-deployment verification
- Troubleshooting steps
- Cost governance setup 
- **Keep this open during deployment**



---

## 🚀 QUICK START (Choose Your Path)

### ⚡ Fastest (40 minutes)
1. **Push Docker Image** (See "Docker Setup" section below)
2. Edit `terraform/environments/staging/terraform.tfvars` 
3. Run:
   ```bash
   cd terraform
   terraform init
   terraform apply -var-file="environments/staging/terraform.tfvars"
   ```
4. Test: `curl http://<ALB_DNS>/health`
5. Application: http://<ALB_DNS>

### 📊 Informed (2 hours)
1. Read **COMBINED_SUMMARY.md** (architecture & costs)
2. Read **DEPLOYMENT_CHECKLIST.md** (follow step-by-step)
3. Deploy with detailed verification

### 🎓 Complete (3+ hours)
1. Read **COMBINED_SUMMARY.md** (overview)
2. Read **DEPLOYMENT_CHECKLIST.md** (detailed instructions)
3. Reference Terraform files for advanced configuration

---

## 📋 FILES TO EDIT BEFORE DEPLOYMENT

**These 2 files MUST be edited before `terraform apply`:**

1. **`terraform/environments/staging/terraform.tfvars`**
   ```hcl
   # Change these:
   db_password = "YourPassword123!@"                   # CHANGE PASSWORD
   ```

2. **`terraform/environments/production/terraform.tfvars`**
   ```hcl
   # Change these:
   db_password = "YourPassword123!@"                   # CHANGE PASSWORD
   ```

**Optional - Cost Governance Settings :**
```hcl
enable_cost_governance = true       # Set to false to disable cost monitoring
monthly_budget = 100                # Monthly spending limit in USD
alert_email = "your-email@example.com"  # Where to send cost alerts
```
-----

## 🐳 DOCKER SETUP (Build & Push)

Before deploying Terraform, ensure your image is in ECR.

**1. Build Image:**

```bash
cd app
docker build -t tic-tac-toe-app:latest .
```

**2. Authenticate & Push:**
*(Replace `12345678` with your AWS Account ID)*

```bash
# Login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 12345678.dkr.ecr.us-east-1.amazonaws.com

# Tag
docker tag tic-tac-toe-app:latest [12345678.dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe:latest](https://12345678.dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe:latest)

# Push
docker push [12345678.dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe:latest](https://12345678.dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe:latest)
```

-----
---

## 🎯 PREREQUISITES

Before starting, verify you have:

- [ ] AWS Account (with billing enabled)
- [ ] AWS CLI configured (`aws configure`)
- [ ] Terraform installed (v1.0+)
- [ ] Linux/MacOS OR WSL2 (for bash - Windows users)

---

## 📊 DETAILED ARCHITECTURE WITH IPs & ZONES
![alt text](Daigram.jpg)
```
┌─────────────────────────────────────────────────────────────────────────┐
│                            AWS REGION: us-east-1                        │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    INTERNET GATEWAY                              │  │
│  │                                                                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                    │                                     │
│                                    ▼                                     │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                 VPC: app-vpc (10.0.0.0/16)                      │  │
│  │                                                                  │  │
│  │  ┌─────────────────────────────────────────────────────────┐   │  │
│  │  │           PUBLIC SUBNETS (ALB TIER)                    │   │  │
│  │  │                                                         │   │  │
│  │  │  ┌──────────────────────┐  ┌──────────────────────┐   │   │  │
│  │  │  │  us-east-1a          │  │  us-east-1b          │   │   │  │
│  │  │  │  Subnet: 10.0.1.0/24 │  │  Subnet: 10.0.2.0/24 │   │   │  │
│  │  │  │  AZ: us-east-1a      │  │  AZ: us-east-1b      │   │   │  │
│  │  │  │                      │  │                      │   │   │  │
│  │  │  │  [ALB Subnet A]      │  │  [ALB Subnet B]      │   │   │  │
│  │  │  │  Route: 0.0.0.0/0    │  │  Route: 0.0.0.0/0    │   │   │  │
│  │  │  │  (IGW)               │  │  (IGW)               │   │   │  │
│  │  │  └──────────────────────┘  └──────────────────────┘   │   │  │
│  │  │                    │                    │              │   │  │
│  │  │                    ▼                    ▼              │   │  │
│  │  │  ┌─────────────────────────────────────────────────┐  │   │  │
│  │  │  │  APPLICATION LOAD BALANCER (ALB)               │  │   │  │
│  │  │  │  Name: app-alb-{env}                           │  │   │  │
│  │  │  │  Port: 80 (HTTP)                               │  │   │  │
│  │  │  │  Target Group: app-tg-{env}                    │  │   │  │
│  │  │  │  Health Check: /health (every 30s)             │  │   │  │
│  │  │  └─────────────────────────────────────────────────┘  │   │  │
│  │  └─────────────────────────────────────────────────────┘   │  │
│  │                         │                                   │  │
│  │                         ▼                                   │  │
│  │  ┌─────────────────────────────────────────────────────┐   │  │
│  │  │        PRIVATE SUBNETS (APP & DB TIER)            │   │  │
│  │  │                                                     │   │  │
│  │  │  ┌──────────────────────┐  ┌──────────────────────┐   │  │
│  │  │  │  us-east-1a          │  │  us-east-1b          │   │  │
│  │  │  │  Subnet: 10.0.10.0/24│  │  Subnet: 10.0.11.0/24│   │  │
│  │  │  │  AZ: us-east-1a      │  │  AZ: us-east-1b      │   │  │
│  │  │  │                      │  │                      │   │  │
│  │  │  │  ┌────────────────┐  │  │  ┌────────────────┐  │   │  │
│  │  │  │  │ ECS FARGATE    │  │  │  │ ECS FARGATE    │  │   │  │
│  │  │  │  │ Task: 1        │  │  │  │ Task: 1        │  │   │  │
│  │  │  │  │ Name: app-     │  │  │  │ Name: app-     │  │   │  │
│  │  │  │  │ {env}-task     │  │  │  │ {env}-task     │  │   │  │
│  │  │  │  │ CPU: 256       │  │  │  │ CPU: 256       │  │   │  │
│  │  │  │  │ Memory: 512MB  │  │  │  │ Memory: 512MB  │  │   │  │
│  │  │  │  │ Port: 5000     │  │  │  │ Port: 5000     │  │   │  │
│  │  │  │  │ Cluster:       │  │  │  │ Cluster:       │  │   │  │
│  │  │  │  │ app-cluster    │  │  │  │ app-cluster    │  │   │  │
│  │  │  │  │ Image: express │  │  │  │ Image: express │  │   │  │
│  │  │  │  │ app (Docker)   │  │  │  │ app (Docker)   │  │   │  │
│  │  │  │  └────────────────┘  │  │  └────────────────┘  │   │  │
│  │  │  │           │           │  │          │           │   │  │
│  │  │  │           ▼           │  │          ▼           │   │  │
│  │  │  │  ┌────────────────┐   │  │  ┌────────────────┐   │   │  │
│  │  │  │  │ SECURITY GROUP │   │  │  │ SECURITY GROUP │   │   │  │
│  │  │  │  │ app-sg-{env}   │   │  │  │ app-sg-{env}   │   │   │  │
│  │  │  │  │ Ingress:       │   │  │  │ Ingress:       │   │   │  │
│  │  │  │  │ 5000 (ALB)     │   │  │  │ 5000 (ALB)     │   │   │  │
│  │  │  │  │ Egress: ALL    │   │  │  │ Egress: ALL    │   │   │  │
│  │  │  │  └────────────────┘   │  │  └────────────────┘   │   │  │
│  │  │  └──────────────────────┘  └──────────────────────┘   │   │  │
│  │  │           │                           │                │   │  │
│  │  │           └─────────────┬─────────────┘                │   │  │
│  │  │                         │                              │   │  │
│  │  │                         ▼                              │   │  │
│  │  │  ┌──────────────────────────────────────────────────┐ │   │  │
│  │  │  │      RDS POSTGRESQL (Shared Across Envs)       │ │   │  │
│  │  │  │      Name: app-db                              │ │   │  │
│  │  │  │      Instance Class: db.t3.micro               │ │   │  │
│  │  │  │      Engine: PostgreSQL 13.x                   │ │   │  │
│  │  │  │      Port: 5432                                │ │   │  │
│  │  │  │      Master User: appuser                      │ │   │  │
│  │  │  │      Master DB: appdb                          │ │   │  │
│  │  │  │      Allocated Storage: 20 GB                  │ │   │  │
│  │  │  │      Backup Retention: 7-14 days               │ │   │  │
│  │  │  │      Multi-AZ: No (Cost Savings)               │ │   │  │
│  │  │  │      Subnet Group: app-db-subnet-group         │ │   │  │
│  │  │  │      Security Group: app-db-sg                 │ │   │  │
│  │  │  │      Ingress: 5432 (ECS tasks)                 │ │   │  │
│  │  │  │      Table: items (id, name, value, created_at)│ │   │  │
│  │  │  └──────────────────────────────────────────────────┘ │   │  │
│  │  │                         │                              │   │  │
│  │  │                         ▼                              │   │  │
│  │  │  ┌──────────────────────────────────────────────────┐ │   │  │
│  │  │  │     AWS SECRETS MANAGER                         │ │   │  │
│  │  │  │     Secret: {env}/rds/password                  │ │   │  │
│  │  │  │     Value: RDS Master Password (Encrypted)      │ │   │  │
│  │  │  │     Used By: ECS Task IAM Role                  │ │   │  │
│  │  │  └──────────────────────────────────────────────────┘ │   │  │
│  │  └─────────────────────────────────────────────────────┘   │  │
│  │                                                             │  │
│  │  ┌─────────────────────────────────────────────────────┐   │  │
│  │  │       NAT GATEWAY (Outbound Internet Access)       │   │  │
│  │  │       Location: Public Subnet (us-east-1a)         │   │  │
│  │  │       Name: app-nat-gateway                        │   │  │
│  │  │       IP: Elastic IP (Auto-assigned)               │   │  │
│  │  │       Route: Private Subnets → NAT → IGW          │   │  │
│  │  └─────────────────────────────────────────────────────┘   │  │
│  │                                                             │  │
│  │  ┌─────────────────────────────────────────────────────┐   │  │
│  │  │       CLOUDWATCH LOGS (Monitoring)                │   │  │
│  │  │       Log Group: /ecs/app-{env}-task              │   │  │
│  │  │       Retention: 30 days                           │   │  │
│  │  │       Contains: ECS application logs               │   │  │
│  │  └─────────────────────────────────────────────────────┘   │  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │    OPTIONAL: COST GOVERNANCE RESOURCES           │  │
│  │                                                             │  │
│  │  ┌────────────────────────────────────────────────────┐    │  │
│  │  │ AWS BUDGETS                                        │    │  │
│  │  │ Budget: app-monthly-budget-{env}                  │    │  │
│  │  │ Limit: $100 (Staging) / $150 (Production)         │    │  │
│  │  │ Thresholds: 80%, 100%, 120%                        │    │  │
│  │  │ Alert: SNS Topic                                   │    │  │
│  │  └────────────────────────────────────────────────────┘    │  │
│  │                          │                                  │  │
│  │                          ▼                                  │  │
│  │  ┌────────────────────────────────────────────────────┐    │  │
│  │  │ SNS TOPIC (Cost Alerts)                            │    │  │
│  │  │ Name: app-cost-alerts-{env}                        │    │  │
│  │  │ Subscriptions: Email (if alert_email set)          │    │  │
│  │  └────────────────────────────────────────────────────┘    │  │
│  │                          │                                  │  │
│  │                          ▼                                  │  │
│  │  ┌────────────────────────────────────────────────────┐    │  │
│  │  │ LAMBDA FUNCTION (Daily Cost Reporter)             │    │  │
│  │  │ Name: app-cost-reporter-{env}                     │    │  │
│  │  │ Runtime: Python 3.11                              │    │  │
│  │  │ Memory: 256 MB                                     │    │  │
│  │  │ Handler: cost_reporter.lambda_handler              │    │  │
│  │  │ Role: app-lambda-role                              │    │  │
│  │  │ Permissions: Cost Explorer, SNS, CloudWatch        │    │  │
│  │  └────────────────────────────────────────────────────┘    │  │
│  │                          │                                  │  │
│  │                          ▼                                  │  │
│  │  ┌────────────────────────────────────────────────────┐    │  │
│  │  │ EVENTBRIDGE RULE (Scheduler)                      │    │  │
│  │  │ Name: app-daily-cost-report-{env}                 │    │  │
│  │  │ Schedule: cron(0 9 * * ? *) [9 AM UTC Daily]      │    │  │
│  │  │ Target: Lambda Function                            │    │  │
│  │  └────────────────────────────────────────────────────┘    │  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘

KEY:
{env} = "staging" or "production"
sg = Security Group
tg = Target Group
db = Database
```

---

### Network Flow Diagram (Data Path)

```
USER REQUESTS
     │
     ▼
  INTERNET
     │
     ▼
INTERNET GATEWAY
     │
     ▼
ALB (Port 80)
├─ Listener Rule: Path = /health
│  └─ Forwards to: app-tg-{env}
│
├─ Listener Rule: Path = /api/*
│  └─ Forwards to: app-tg-{env}
│
└─ Health Check: /health every 30s
     │
     ▼
ECS FARGATE TASKS (Private Subnet)
├─ Port 5000 (App)
├─ Security Group: app-sg-{env}
│  └─ Allows: 5000 from ALB
│  └─ Allows: All Egress
│
├─ Environment Variables:
│  ├─ DB_HOST: RDS endpoint
│  ├─ DB_PORT: 5432
│  ├─ DB_NAME: appdb
│  ├─ DB_USER: appuser
│  └─ DB_PASSWORD: from Secrets Manager
│
└─ Logs Output: CloudWatch Logs
     │
     ▼
RDS POSTGRESQL (Private Subnet)
├─ Endpoint: app-db.{random}.us-east-1.rds.amazonaws.com
├─ Port: 5432
├─ Database: appdb
├─ Table: items
│  ├─ id (SERIAL PRIMARY KEY)
│  ├─ name (VARCHAR)
│  ├─ value (INTEGER)
│  └─ created_at (TIMESTAMP)
│
└─ Security Group: app-db-sg
   └─ Allows: 5432 from ECS SG
```

---

### IP Address Allocation Summary

```
┌──────────────────────────────────────────────────────┐
│           VPC CIDR & SUBNET BREAKDOWN                │
├──────────────────────────────────────────────────────┤
│ VPC CIDR:              10.0.0.0/16                   │
│ Total IPs:             65,536                        │
│                                                      │
│ PUBLIC SUBNETS (ALB):                               │
│ ├─ us-east-1a:         10.0.1.0/24   (256 IPs)     │
│ └─ us-east-1b:         10.0.2.0/24   (256 IPs)     │
│                                                      │
│ PRIVATE SUBNETS (ECS + RDS):                        │
│ ├─ us-east-1a:         10.0.10.0/24  (256 IPs)     │
│ └─ us-east-1b:         10.0.11.0/24  (256 IPs)     │
│                                                      │
│ Available for future use:                           │
│ └─ 10.0.3.0 - 10.0.9.0                             │
│    10.0.12.0 - 10.0.255.0                          │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

### IAM Roles & Permissions

```
┌──────────────────────────────────────────────────────┐
│           IAM ROLES & POLICIES                       │
├──────────────────────────────────────────────────────┤
│                                                      │
│ ECS TASK EXECUTION ROLE                             │
│ ├─ Name: app-ecs-task-execution-role-{env}         │
│ ├─ Used by: ECS Fargate Runtime                     │
│ └─ Permissions:                                      │
│    ├─ CloudWatch Logs: Create log streams/groups    │
│    ├─ ECR: Get authorization token                  │
│    └─ Secrets Manager: Get RDS password             │
│                                                      │
│ ECS TASK ROLE                                       │
│ ├─ Name: app-ecs-task-role-{env}                   │
│ ├─ Used by: Application (container)                 │
│ └─ Permissions:                                      │
│    ├─ CloudWatch Logs: Put log events               │
│    └─ Secrets Manager: Get RDS secret               │
│                                                      │
│ LAMBDA EXECUTION ROLE (Option E only)               │
│ ├─ Name: app-lambda-role                            │
│ ├─ Used by: Cost Reporter Lambda                    │
│ └─ Permissions:                                      │
│    ├─ Cost Explorer: GetCostAndUsage                │
│    ├─ SNS: Publish                                  │
│    └─ CloudWatch Logs: Create & Put logs            │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

### Security Groups Summary

```
┌──────────────────────────────────────────────────────┐
│           SECURITY GROUPS                            │
├──────────────────────────────────────────────────────┤
│                                                      │
│ ALB SECURITY GROUP: app-alb-sg-{env}               │
│ ├─ Ingress:                                         │
│ │  └─ Port 80 (HTTP) from 0.0.0.0/0 (Public)      │
│ └─ Egress:                                          │
│    └─ All traffic to 0.0.0.0/0                      │
│                                                      │
│ ECS TASK SECURITY GROUP: app-sg-{env}              │
│ ├─ Ingress:                                         │
│ │  └─ Port 5000 (TCP) from app-alb-sg-{env}       │
│ └─ Egress:                                          │
│    └─ All traffic (for NAT → Internet & DB)        │
│                                                      │
│ RDS SECURITY GROUP: app-db-sg                       │
│ ├─ Ingress:                                         │
│ │  └─ Port 5432 (TCP) from app-sg-{env}           │
│ └─ Egress:                                          │
│    └─ All traffic                                   │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## 💰 MONTHLY COST BREAKDOWN

| Component | Cost | Free Tier? |
|-----------|------|-----------|
| VPC + NAT Gateway | $12/month | No |
| ECS Fargate (1 task) | $20/month | ~Yes* |
| RDS PostgreSQL (512MB) | $15/month | ~Yes* |
| Data Transfer | ~$3/month | No |
| **Total without(Cost Governance)** | **~$50/month** | Yes* |
| **with(Cost Governance)** | **~$1.30/month** | Yes* |
| **TOTAL** | **~$51.30/month** | - |

*Free tier covers ~750 hours ECS + ~1 year RDS. After free tier, costs are as shown.

---

## 📁 PROJECT STRUCTURE

```
AWS Infrastructure Setup/
├── README.md                          ← Main entry point (YOU ARE HERE)
├── QUICK_START.md                     ← 5-minute deployment guide
├── COMBINED_SUMMARY.md                ← Architecture & cost overview
├── DEPLOYMENT_CHECKLIST.md            ← Step-by-step deployment
└── terraform/
    ├── main.tf                        ← Core infrastructure
    ├── variables.tf                   ← Variable definitions
    ├── cost_governance_resources.tf   ← Cost monitoring 
    ├── tagging_resources.tf           ← Tagging strategy 
    ├── cost_reporter.py               ← Lambda function 
    ├── cost_reporter.zip              ← Lambda package 
    └── environments/
        ├── staging/
        │   └── terraform.tfvars       ← EDIT THIS (staging)
        └── production/
            └── terraform.tfvars       ← EDIT THIS (production)
```

---

## ✅ POST-DEPLOYMENT VERIFICATION

After running `terraform apply`, verify everything works:

```bash
# 1. Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[0].DNSName' --output text)

# 2. Test health endpoint
curl http://$ALB_DNS/health
# Expected: {"status": "ok", "database": "connected"}

# 3. List items
curl http://$ALB_DNS/api/items
# Expected: [] (empty initially) or [items list]

# 4. Create item
curl -X POST http://$ALB_DNS/api/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Item", "value": 100}'
# Expected: {"id": 1, "name": "Test Item", "value": 100}

# 5. Check logs
aws logs tail /ecs/app-staging-task --follow
```

---

## 🛠️ COMMON ISSUES & SOLUTIONS

| Issue | Solution |
|-------|----------|
| **"invalid credentials"** | Run `aws configure` and verify AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY |
| **"terraform: command not found"** | Install Terraform from terraform.io |
| **"docker_hub_username: no default"** | Edit terraform.tfvars file - add your Docker Hub username |
| **ALB returns 503 (Bad Gateway)** | Wait 2-3 minutes for ECS task to start, then retry |
| **Database connection fails** | Verify RDS password in terraform.tfvars matches |
| **Cost alerts not working** | Check `alert_email` is set and you confirmed SNS subscription |

---

## 📖 NEXT STEPS

1. **Choose Your Path** (above) based on available time
2. **Read the Right Documentation**:
   - Quick deployment → QUICK_START.md
   - Full understanding → COMBINED_SUMMARY.md
   - Step-by-step guidance → DEPLOYMENT_CHECKLIST.md
3. **Edit 2 Configuration Files** (terraform.tfvars)
4. **Deploy** (terraform init + apply)
5. **Test** (curl your ALB DNS)
6. **Monitor** (CloudWatch Logs or AWS Dashboard)

---

## 🆘 GETTING HELP

| Need | Read |
|------|------|
| **Quick deployment (5 min)** | QUICK_START.md |
| **Understand architecture** | COMBINED_SUMMARY.md |
| **Step-by-step deployment** | DEPLOYMENT_CHECKLIST.md |
| **Application API details** | COMBINED_SUMMARY.md - Application section |
| **Cost breakdown** | COMBINED_SUMMARY.md - Cost Analysis section |

---

## 📞 SUPPORT RESOURCES

- **Terraform**: https://www.terraform.io/docs
- **AWS ECS**: https://docs.aws.amazon.com/ecs/
- **AWS RDS**: https://docs.aws.amazon.com/rds/
- **AWS ALB**: https://docs.aws.amazon.com/elasticloadbalancing/

---

## 🔐 SECURITY NOTES

⚠️ **Important Before Production**:
1. Change all default passwords (terraform.tfvars)
2. Use strong database passwords (minimum 16 chars, mixed case, numbers, symbols)
3. Enable ALB HTTPS/TLS (not included in this setup)
4. Restrict security group ingress to your IP only (before production)
5. Enable VPC Flow Logs for monitoring
6. Use AWS Secrets Manager for credential rotation

---

**Ready to deploy?** 

👉 Start with **[QUICK_START.md](./QUICK_START.md)** (5 min) or **[COMBINED_SUMMARY.md](./COMBINED_SUMMARY.md)** (15-30 min)

*Last Updated: December 2025*
#   A W S - I n f r a s t r u c t u r e - S e t u p  
 