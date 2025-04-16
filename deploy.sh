#!/bin/bash
# Make script executable with: chmod +x deploy.sh

# Exit on error
set -e

# Check for required environment variables
if [ -z "$SLACK_WEBHOOK_URL" ] || [ -z "$GOOGLE_MAPS_API_KEY" ] || [ -z "$RSS_FEED_URL" ]; then
    echo "Error: Required environment variables are not set"
    echo "Please set: SLACK_WEBHOOK_URL, GOOGLE_MAPS_API_KEY, RSS_FEED_URL"
    exit 1
fi

# Deploy AWS Infrastructure
echo "Deploying AWS Infrastructure..."
cd infrastructure
aws cloudformation deploy \
    --template-file template.yaml \
    --stack-name sinkhole-detector \
    --parameter-overrides \
        SlackWebhookUrl=$SLACK_WEBHOOK_URL \
        RssFeedUrl=$RSS_FEED_URL \
    --capabilities CAPABILITY_IAM

# Get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name sinkhole-detector \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
    --output text)

# Install and build backend
echo "Setting up backend..."
cd ../backend/collectors
npm install
zip -r ../../infrastructure/collector.zip .
cd ../api
npm install
zip -r ../../infrastructure/api.zip .

# Update Lambda functions
echo "Updating Lambda functions..."
cd ../../infrastructure
aws lambda update-function-code \
    --function-name sinkhole-detector-rss-collector \
    --zip-file fileb://collector.zip

aws lambda update-function-code \
    --function-name sinkhole-detector-api \
    --zip-file fileb://api.zip

# Setup frontend
echo "Setting up frontend..."
cd ../frontend
npm install

# Create .env file
echo "VITE_GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY" > .env
echo "VITE_API_ENDPOINT=$API_ENDPOINT" >> .env

# Build frontend
npm run build

echo "Deployment complete!"
echo "API Endpoint: $API_ENDPOINT"
echo "Next steps:"
echo "1. Upload the frontend/dist directory to your web hosting service"
echo "2. Configure CORS in API Gateway if needed"
echo "3. Test the application"
