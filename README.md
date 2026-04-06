# Cloud Resume Challenge — Estelle Foreman

A fully serverless resume website built on AWS, based on the [Cloud Resume Challenge](https://cloudresumechallenge.dev/) by Forrest Brazeal.

**Live site:** https://d2k170rvl2u2vi.cloudfront.net

---

## Architecture

```
Visitor → CloudFront (HTTPS) → S3 (static files)
                ↓
         JavaScript fetch()
                ↓
         API Gateway (HTTP API)
                ↓
         Lambda (Python 3.13)
                ↓
         DynamoDB (visitor count)
```

**CI/CD:** GitHub Actions automatically deploys frontend changes to S3 and invalidates the CloudFront cache on every push to `main`.

---

## Services Used

| Service | Purpose | Why not the alternative? |
|---|---|---|
| S3 | Hosts static HTML/CSS/JS | Cheaper and simpler than EC2 for static files |
| CloudFront | HTTPS, global CDN | S3 static hosting is HTTP only |
| API Gateway | Public HTTP endpoint | Exposes Lambda without managing a server |
| Lambda (Python) | Visitor counter logic | Serverless — no idle cost, auto-scales |
| DynamoDB | Stores visitor count | No relational data needed — NoSQL fits perfectly |
| IAM | Least-privilege access | Every service scoped to minimum required permissions |
| CloudWatch | Lambda logs and monitoring | Built-in observability at no extra setup cost |
| GitHub Actions | CI/CD pipeline | Automates deploy on push — no manual S3 sync |

---

## Project Structure

```
cloud-resume-challenge/
├── frontend/
│   ├── index.html          # Resume page
│   ├── style.css           # Styling
│   └── counter.js          # Visitor counter JavaScript
├── backend/
│   ├── lambda_function.py  # Visitor counter Lambda
│   └── requirements.txt    # Python dependencies
├── infrastructure/
│   └── notes.md            # Architecture decisions log
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions CI/CD
└── README.md
```

---

## Key Decisions & Trade-offs

### Why DynamoDB instead of RDS?
The visitor counter is a single key-value record. There are no joins, no relational queries, no complex schema. DynamoDB on PAY_PER_REQUEST billing costs fractions of a cent per month for this workload. RDS would require a running instance costing $15-20/month minimum even with zero traffic.

### Why CloudFront instead of direct S3 URL?
S3 static website hosting is HTTP only. CloudFront adds HTTPS (required for browser security), global edge caching (faster load times worldwide), and a clean shareable URL. The trade-off is a 10-15 minute propagation delay when deploying updates — mitigated by the CloudFront cache invalidation step in the CI/CD pipeline.

### Why API Gateway HTTP API instead of REST API?
HTTP API (v2) is simpler, faster, and roughly 70% cheaper than REST API (v1) for this use case. REST API adds features like request validation, usage plans, and API keys — none of which are needed for a single GET endpoint returning a visitor count.

### IAM approach
`estelle-dev` IAM user follows least-privilege. Permissions were added incrementally as each service required them — not granted as AdministratorAccess upfront. This mirrors real-world Cloud Support scenarios where over-permissioned users are a common support escalation.

---

## What I Learned

- How to configure AWS CLI and IAM from scratch with security-first thinking
- The difference between S3 static hosting and CloudFront distribution
- How Lambda, API Gateway, and DynamoDB work together as a serverless stack
- Why CORS headers matter and how to configure them in Lambda responses
- How GitHub Actions secrets work and how to scope them safely
- How to read and debug IAM AccessDenied errors — the most common real-world cloud support issue

---

## Phases

- [x] Phase 0: Local environment setup (Homebrew, Git, Python, AWS CLI, VS Code)
- [x] Phase 1: AWS account hardening (MFA, IAM user, billing alerts)
- [x] Phase 2: Resume HTML/CSS built from existing PDF resume
- [x] Phase 3: S3 static website hosting
- [x] Phase 4: Serverless visitor counter (DynamoDB + Lambda + API Gateway)
- [x] Phase 5: CloudFront HTTPS distribution
- [x] Phase 6: GitHub Actions CI/CD pipeline
- [ ] Phase 7 (optional): Custom domain via Route 53 + ACM certificate

---

## Cost

This project runs almost entirely within the AWS Free Tier:
- S3: Free tier covers 5GB storage and 20,000 GET requests/month
- CloudFront: Free tier covers 1TB data transfer and 10M requests/month
- Lambda: Free tier covers 1M invocations/month
- DynamoDB: Free tier covers 25GB storage and 25 read/write capacity units
- API Gateway: Free tier covers 1M HTTP API calls/month

Estimated monthly cost after free tier: **under $1.00**


## Infrastructure as Code (Project 3)

The full stack is also available as a CloudFormation template
at `infrastructure/cloudformation/template.yml`.

One command deploys all eight resources in the correct order:

    aws cloudformation deploy \
      --template-file infrastructure/cloudformation/template.yml \
      --stack-name cloud-resume-cfn-stack \
      --capabilities CAPABILITY_NAMED_IAM \
      --region us-east-1

### What the template provisions
- S3 bucket with static website hosting
- CloudFront HTTPS distribution
- DynamoDB table (PAY_PER_REQUEST)
- Lambda function (Python 3.13) with inline code
- API Gateway HTTP API with GET /count route
- IAM execution role scoped to exact DynamoDB table ARN
- Lambda permission for API Gateway invocation

### Key CloudFormation concepts demonstrated
- Parameters for reusability across environments
- !Ref and !GetAtt for resource cross-referencing
- !Sub for dynamic string construction
- Outputs for automatic value surfacing post-deployment
- Dependency graph inferred from resource references


## Terraform (Project 4)

The full stack is also available as a Terraform configuration
at `infrastructure/terraform/`.

Four commands to deploy:

    cd infrastructure/terraform
    terraform init
    terraform plan
    terraform apply

### What the configuration provisions
- S3 bucket with static website hosting
- CloudFront HTTPS distribution
- DynamoDB table (PAY_PER_REQUEST)
- Lambda function (Python 3.13) with inline code
- API Gateway HTTP API with GET /count route
- IAM execution role scoped to exact DynamoDB table ARN
- Lambda permission for API Gateway invocation

### Key Terraform concepts demonstrated
- providers.tf for AWS provider configuration
- variables.tf for reusable input variables
- outputs.tf for automatic value surfacing post-deployment
- Data sources for read-only AWS lookups
- Resource references using dot notation
- depends_on for explicit dependency management
- jsonencode() for inline IAM policy documents
- source_code_hash for Lambda code change detection