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