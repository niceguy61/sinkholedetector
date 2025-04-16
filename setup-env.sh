#!/bin/bash

# Interactive environment variable setup script
set -e

check_environment_variables() {
    local all_set=true
    local variables=("SLACK_WEBHOOK_URL" "GOOGLE_MAPS_API_KEY" "RSS_FEED_URL")
    
    for var in "${variables[@]}"; do
        if [ -z "${!var}" ]; then
            echo -e "\033[0;31mMissing: $var\033[0m"
            all_set=false
        else
            echo -e "\033[0;32m$var is set\033[0m"
        fi
    done
    
    $all_set
}

echo -e "\033[0;36m싱크홀 감지 시스템 환경 설정 / Sinkhole Detection System Environment Setup\033[0m"
echo -e "\033[0;36m============================================================\033[0m"

# Check if variables are already set
if check_environment_variables; then
    read -p "Environment variables are already set. Do you want to update them? (y/n) " response
    if [ "$response" != "y" ]; then
        echo "Keeping existing environment variables. You can now run ./deploy.sh"
        exit 0
    fi
fi

# Slack Webhook URL
echo -e "\n\033[0;33mSlack Webhook URL\033[0m"
echo "You can get this from your Slack App's Incoming Webhooks configuration"
read -p "Enter your Slack Webhook URL: " slack_webhook
if [ ! -z "$slack_webhook" ]; then
    export SLACK_WEBHOOK_URL="$slack_webhook"
fi

# Google Maps API Key
echo -e "\n\033[0;33mGoogle Maps API Key\033[0m"
echo "You can get this from Google Cloud Console > APIs & Services > Credentials"
read -p "Enter your Google Maps API Key: " maps_key
if [ ! -z "$maps_key" ]; then
    export GOOGLE_MAPS_API_KEY="$maps_key"
fi

# RSS Feed URL
echo -e "\n\033[0;33mRSS Feed URL\033[0m"
echo "Enter the URL for the news RSS feed"
read -p "Enter your RSS Feed URL: " rss_url
if [ ! -z "$rss_url" ]; then
    export RSS_FEED_URL="$rss_url"
fi

echo -e "\nChecking environment variables..."
if check_environment_variables; then
    echo -e "\n\033[0;32mAll environment variables are set successfully!\033[0m"
    echo "You can now run ./deploy.sh"
    
    # Optionally save to a .env file for future use
    read -p "Would you like to save these variables to a .env file for future use? (y/n) " save_to_file
    if [ "$save_to_file" = "y" ]; then
        cat > .env << EOF
SLACK_WEBHOOK_URL=$SLACK_WEBHOOK_URL
GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY
RSS_FEED_URL=$RSS_FEED_URL
EOF
        echo "Variables saved to .env file"
    fi
else
    echo -e "\n\033[0;31mSome environment variables are still not set. Please run this script again.\033[0m"
fi