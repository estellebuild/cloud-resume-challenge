## IAM Setup
Created IAM user: estelle-dev
Policies attached: S3, DynamoDB, Lambda, CloudFront full access
Reason: Least-privilege — only granting what this project needs.
Root account: MFA enabled, not used for development.
Billing alert: Zero spend budget configured.
## S3 Static Hosting
Bucket: estelle-cloud-resume
Region: us-east-1
Hosting: S3 static website (HTTP only at this stage)
Decision: No CloudFront yet — adding in Phase 5 for HTTPS + CDN.
Trade-off: HTTP is insecure and slower globally. Acceptable for dev phase.
URL: http://estelle-cloud-resume.s3-website-us-east-1.amazonaws.com

## IAM Policy Update
Added IAMFullAccess to estelle-dev user.
Reason: Needed to create Lambda execution roles.
Note: In a production team environment this would be handled by
a separate IAM admin — developers don't typically self-grant IAM access.

## Permissions pattern observed
Each new AWS service requires explicit IAM permissions.
Had to add AmazonAPIGatewayAdministrator to estelle-dev
when setting up API Gateway — same pattern as IAMFullAccess
for role creation. Least-privilege means adding permissions
incrementally as needed, not granting everything upfront.

## CloudFront
Distribution ID: E1B3ZF1S2I3KAH
Domain: https://d2k170rv12u2vi.cloudfront.net
Origin: estelle-cloud-resume.s3-website-us-east-1.amazonaws.com
ViewerProtocolPolicy: redirect-to-https
Reason: S3 static hosting is HTTP only. CloudFront adds HTTPS,
global edge caching, and a shareable URL.
Trade-off: CloudFront adds ~10-15 min propagation delay when
deploying updates. Mitigated by cache invalidation in CI/CD.


## CloudFormation (Project 3)
Stack name: cloud-resume-cfn-stack
Template: infrastructure/cloudformation/template.yml
Resources: S3, CloudFront, DynamoDB, Lambda, API Gateway, IAM
CloudFront URL: https://d33ptgd3m4ret9.cloudfront.net
API Endpoint: https://0tf9ysp368.execute-api.us-east-1.amazonaws.com/prod/count

Decision: Converted the full CLI-built stack to IaC.
Why: CloudFormation manages dependency order automatically,
makes the stack reproducible, and reflects how real teams
manage infrastructure.

Key concepts learned:
- !Ref, !GetAtt, !Sub intrinsic functions
- CAPABILITY_NAMED_IAM for IAM resource acknowledgment
- Outputs for surfacing resource values post-deployment
- Dependency graph built automatically from references


## Terraform (Project 4)
Stack: infrastructure/terraform/
Resources: S3, CloudFront, DynamoDB, Lambda, API Gateway, IAM
CloudFront URL: https://dl20w1pqc121e.cloudfront.net
API Endpoint: https://1jg5zpbssl.execute-api.us-east-1.amazonaws.com/prod/count
DynamoDB Table: cloud-resume-tf-visitor-count
S3 Bucket: cloud-resume-tf-898319808606

Decision: Converted full stack to Terraform HCL.
Why: Terraform is cloud-agnostic unlike CloudFormation which
is AWS-only. Adds HCL, state management, and terraform plan
workflow to skill set.

Key differences from CloudFormation:
- HCL syntax instead of YAML
- terraform plan shows exact changes before applying
- State file tracks real-world infrastructure locally
- Resource references use dot notation (aws_s3_bucket.resume.arn)
  instead of !GetAtt
- No CAPABILITY_NAMED_IAM flag needed
- Works across AWS, Azure, GCP

Key concepts learned:
- providers.tf — tells Terraform which cloud platform to use
- variables.tf — equivalent to CloudFormation Parameters
- main.tf — all resources defined in HCL
- outputs.tf — equivalent to CloudFormation Outputs
- data sources — read-only lookups (aws_caller_identity, archive_file)
- depends_on — explicit dependency when references are not enough
- jsonencode() — converts HCL objects to JSON for AWS policies
- source_code_hash — detects Lambda code changes automatically