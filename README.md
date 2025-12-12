
# AWS Infrastructure Setup: Tic-Tac-Toe Application

**Status**: ✅ READY FOR DEPLOYMENT  
**Cost**: ~$51/month ($50 + Cost Optimization & Governance: $1.30)  
**Time to Deploy**: 40 minutes  

---

## 🎯 MINIMAL STEP-BY-STEP (Just 4 Steps)

### Step 1: Build & Push Docker Image
```bash
# Build the application image
cd app
docker build -t tic-tac-toe-app:latest .

# Get your AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Authenticate to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

# Tag and push to ECR
docker tag tic-tac-toe-app:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe:latest

cd ..
```

### Step 2: Edit Configuration
```bash
# Edit staging configuration
nano terraform/environments/staging/terraform.tfvars

# Change ONLY this value:
db_password = "YourStrongPassword123!@"
```

### Step 3: Deploy with Terraform
```bash
cd terraform
terraform init
terraform apply -var-file="environments/staging/terraform.tfvars"
```
**Type "yes" when prompted**

### Step 4: Test Your Application
```bash
# Get ALB DNS from Terraform output
# It looks like: app-alb-staging-123456.us-east-1.elb.amazonaws.com

# Test health endpoint
curl http://YOUR-ALB-DNS-HERE/health
# Expected: {"status": "ok", "database": "connected"}

# Open in browser
# http://YOUR-ALB-DNS-HERE
```

**That's it! Your Tic-Tac-Toe app is live.** ✅

---

## 🐳 DOCKER IMAGE STATUS

The application has been successfully built and pushed to AWS ECR:

```bash
# Image URI (Replace 12345678 with your AWS Account ID)
12345678.dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe:latest
```

**Image Details:**
- Tag: latest
- Build: December 12, 2025
- Status: ✅ Successfully pushed to ECR
- Size: 739 MB

**⚠️ IMPORTANT: Replace '12345678' with your actual AWS Account ID**
```bash
# Get your account ID:
aws sts get-caller-identity --query Account --output text
# Example: 999888777666.dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe:latest
```

---

## 🎮 APPLICATION FEATURES

### ✅ Key Features
- Two-player Tic-Tac-Toe game with player name tracking
- Game state persistence to PostgreSQL
- Player scoring and statistics (wins/losses/draws)
- RESTful API for all game operations
- Docker containerized and deployed to ECR
- AWS RDS PostgreSQL integration
- CloudWatch logging for all operations

### ✅ Working Deployment Status
**Production Environment:**
```
Status: Ready for Deployment
Cluster: test-production-cluster
Service: test-production-service
Database: test-production-db (RDS PostgreSQL)
Region: us-east-1
Container Image: [YOUR-ACCOUNT-ID].dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe:latest
```

**Staging Environment:**
```
Status: Ready for Deployment
Cluster: test-staging-cluster
Service: test-staging-service
Database: test-staging-db (RDS PostgreSQL)
Region: us-east-1
Container Image: [YOUR-ACCOUNT-ID].dkr.ecr.us-east-1.amazonaws.com/tic-tac-toe:latest
```

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
1. **Push Docker Image** (See "Docker Setup" section above)
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

**Optional - Cost Governance Settings:**
```hcl
enable_cost_governance = true       # Set to false to disable cost monitoring
monthly_budget = 100                # Monthly spending limit in USD
alert_email = "your-email@example.com"  # Where to send cost alerts
```

---

## 🎯 PREREQUISITES

Before starting, verify you have:

- [ ] AWS Account (with billing enabled)
- [ ] AWS CLI configured (`aws configure`)
- [ ] Terraform installed (v1.0+)
- [ ] Docker installed and running
- [ ] Linux/MacOS OR WSL2 (for bash - Windows users)

---

## 🏗️ ARCHITECTURE OVERVIEW

![Daigram](https://github.com/user-attachments/assets/3923f3e6-a1ce-4302-8365-816fb0f77b07)


### Network Architecture:
```
Internet Users
     ↓
Application Load Balancer (Public Subnet)
     ↓
ECS Fargate Tasks (Private Subnet - 10.0.10.0/24, 10.0.11.0/24)
     ↓
RDS PostgreSQL (Private Subnet - Database only)
```

### Visual Architecture:

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
│  │  │  │  │ Image: tic-tac-toe │ │  │  │ Image: tic-tac-toe │ │   │  │
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
│  │  └─────────────────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

---

## 💰 MONTHLY COST BREAKDOWN

| Component | Cost | Free Tier? |
|-----------|------|-----------|
| VPC + NAT Gateway | $12/month | No |
| ECS Fargate (1 task) | $20/month | ~Yes* |
| RDS PostgreSQL (512MB) | $15/month | ~Yes* |
| Data Transfer | ~$3/month | No |
| **Total without Cost Governance** | **~$50/month** | Yes* |
| **Cost Governance** | **~$1.30/month** | Yes* |
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
├── app/                               ← Tic-Tac-Toe application source
│   ├── Dockerfile                     ← Container definition
│   ├── requirements.txt               ← Python dependencies
│   └── app.py                         ← Main application
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

# 3. Test game API
curl http://$ALB_DNS/api/games
# Expected: [] (empty initially) or [games list]

# 4. Check logs
aws logs tail /ecs/app-staging-task --follow
```

---

## 🛠️ TROUBLESHOOTING

### Docker Issues
**Docker Desktop Won't Start**
- Ensure CPU virtualization is enabled in BIOS (Intel VT-x or AMD SVM)
- Windows: Enable "Virtual Machine Platform" feature
  ```powershell
  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform
  ```
- Restart the computer after enabling

**Docker Build Fails with Dependencies**
- The Dockerfile uses `python:3.10-slim` (not Alpine) for better psycopg2 support
- Ensure system packages are installed: `apt-get update && apt-get install -y build-essential libpq-dev`

**Unable to Push to ECR**
- Verify AWS credentials: `aws sts get-caller-identity`
- Re-authenticate: `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR-ACCOUNT-ID.dkr.ecr.us-east-1.amazonaws.com`

### Terraform Issues
| Issue | Solution |
|-------|----------|
| **"invalid credentials"** | Run `aws configure` and verify AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY |
| **"terraform: command not found"** | Install Terraform from terraform.io |
| **ALB returns 503 (Bad Gateway)** | Wait 2-3 minutes for ECS task to start, then retry |
| **Database connection fails** | Verify RDS password in terraform.tfvars matches |
| **Cost alerts not working** | Check `alert_email` is set and you confirmed SNS subscription |

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

## 📞 SUPPORT RESOURCES

- **Terraform**: https://www.terraform.io/docs
- **AWS ECS**: https://docs.aws.amazon.com/ecs/
- **AWS RDS**: https://docs.aws.amazon.com/rds/
- **AWS ALB**: https://docs.aws.amazon.com/elasticloadbalancing/

---

**Ready to deploy?** 

👉 Start with **[QUICK_START.md](./QUICK_START.md)** (5 min) or **[COMBINED_SUMMARY.md](./COMBINED_SUMMARY.md)** (15-30 min)

*Last Updated: December 2025*
```
