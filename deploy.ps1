# Windows PowerShell deployment script

# Exit on error
$ErrorActionPreference = "Stop"

# Check for required environment variables
if (-not $env:SLACK_WEBHOOK_URL -or -not $env:GOOGLE_MAPS_API_KEY -or -not $env:RSS_FEED_URL) {
    Write-Error "Error: Required environment variables are not set"
    Write-Host "Please set: SLACK_WEBHOOK_URL, GOOGLE_MAPS_API_KEY, RSS_FEED_URL"
    exit 1
}

# Deploy AWS Infrastructure
Write-Host "Deploying AWS Infrastructure..."
Set-Location -Path infrastructure
aws cloudformation deploy `
    --template-file template.yaml `
    --stack-name sinkhole-detector-1 `
    --parameter-overrides `
        SlackWebhookUrl=$env:SLACK_WEBHOOK_URL `
        RssFeedUrl=$env:RSS_FEED_URL `
    --capabilities CAPABILITY_IAM

# Get API endpoint
$API_ENDPOINT = aws cloudformation describe-stacks `
    --stack-name sinkhole-detector-1 `
    --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' `
    --output text

# Install and build backend
Write-Host "Setting up backend..."
Set-Location -Path ..\backend\collectors
npm install
Compress-Archive -Path * -DestinationPath ..\..\infrastructure\collector.zip -Force
Set-Location -Path ..\api
npm install
Compress-Archive -Path * -DestinationPath ..\..\infrastructure\api.zip -Force

# Update Lambda functions
Write-Host "Updating Lambda functions..."
Set-Location -Path ..\..\infrastructure
aws lambda update-function-code `
    --function-name sinkhole-detector-1-rss-collector `
    --zip-file fileb://collector.zip

aws lambda update-function-code `
    --function-name sinkhole-detector-1-api `
    --zip-file fileb://api.zip

# Setup frontend
Write-Host "Setting up frontend..."
Set-Location -Path ..\frontend
npm install

# Create .env file
Set-Content -Path .env -Value "VITE_GOOGLE_MAPS_API_KEY=$env:GOOGLE_MAPS_API_KEY"
Add-Content -Path .env -Value "VITE_API_ENDPOINT=$API_ENDPOINT"

# Build frontend
npm run build

# Get S3 bucket name and CloudFront distribution ID
$S3_BUCKET = aws cloudformation describe-stacks `
    --stack-name sinkhole-detector-1 `
    --query "Stacks[0].Outputs[?OutputKey=='FrontendBucketName'].OutputValue" `
    --output text

$CLOUDFRONT_DIST_ID = aws cloudformation describe-stacks `
    --stack-name sinkhole-detector-1 `
    --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue" `
    --output text

$CLOUDFRONT_DOMAIN = aws cloudformation describe-stacks `
    --stack-name sinkhole-detector-1 `
    --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionDomain'].OutputValue" `
    --output text

# Upload frontend build to S3
Write-Host "Uploading frontend build to S3..."
aws s3 sync dist/ "s3://$S3_BUCKET/" --delete

# Invalidate CloudFront cache
Write-Host "Invalidating CloudFront cache..."
aws cloudfront create-invalidation `
    --distribution-id $CLOUDFRONT_DIST_ID `
    --paths "/*"

Write-Host "Deployment complete!"
Write-Host "API Endpoint: $API_ENDPOINT"
Write-Host "Frontend URL: https://$CLOUDFRONT_DOMAIN"
Write-Host "Please wait a few minutes for the CloudFront invalidation to complete."

