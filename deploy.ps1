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
    --stack-name sinkhole-detector `
    --parameter-overrides `
        SlackWebhookUrl=$env:SLACK_WEBHOOK_URL `
        RssFeedUrl=$env:RSS_FEED_URL `
    --capabilities CAPABILITY_IAM

# Get API endpoint
$API_ENDPOINT = aws cloudformation describe-stacks `
    --stack-name sinkhole-detector `
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
    --function-name sinkhole-detector-rss-collector `
    --zip-file fileb://collector.zip

aws lambda update-function-code `
    --function-name sinkhole-detector-api `
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

Write-Host "Deployment complete!"
Write-Host "API Endpoint: $API_ENDPOINT"
Write-Host "Next steps:"
Write-Host "1. Upload the frontend/dist directory to your web hosting service"
Write-Host "2. Configure CORS in API Gateway if needed"
Write-Host "3. Test the application"