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