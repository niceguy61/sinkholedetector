# Interactive environment variable setup script
$ErrorActionPreference = "Stop"

function Test-EnvironmentVariables {
    $variables = @(
        "SLACK_WEBHOOK_URL",
        "GOOGLE_MAPS_API_KEY",
        "RSS_FEED_URL"
    )
    
    $allSet = $true
    foreach ($var in $variables) {
        if (-not (Get-Item "env:$var" -ErrorAction SilentlyContinue)) {
            Write-Host "Missing: $var" -ForegroundColor Red
            $allSet = $false
        } else {
            Write-Host "$var is set" -ForegroundColor Green
        }
    }
    return $allSet
}

Write-Host "싱크홀 감지 시스템 환경 설정 / Sinkhole Detection System Environment Setup" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Check if variables are already set
$varsSet = Test-EnvironmentVariables
if ($varsSet) {
    $response = Read-Host "Environment variables are already set. Do you want to update them? (y/n)"
    if ($response -ne "y") {
        Write-Host "Keeping existing environment variables. You can now run .\deploy.ps1"
        exit 0
    }
}

# Slack Webhook URL
Write-Host "`nSlack Webhook URL" -ForegroundColor Yellow
Write-Host "You can get this from your Slack App's Incoming Webhooks configuration"
$slackWebhook = Read-Host "Enter your Slack Webhook URL"
if ($slackWebhook) {
    $env:SLACK_WEBHOOK_URL = $slackWebhook
}

# Google Maps API Key
Write-Host "`nGoogle Maps API Key" -ForegroundColor Yellow
Write-Host "You can get this from Google Cloud Console > APIs & Services > Credentials"
$mapsKey = Read-Host "Enter your Google Maps API Key"
if ($mapsKey) {
    $env:GOOGLE_MAPS_API_KEY = $mapsKey
}

# RSS Feed URL
Write-Host "`nRSS Feed URL" -ForegroundColor Yellow
Write-Host "Enter the URL for the news RSS feed"
$rssUrl = Read-Host "Enter your RSS Feed URL"
if ($rssUrl) {
    $env:RSS_FEED_URL = $rssUrl
}

Write-Host "`nChecking environment variables..."
$varsSet = Test-EnvironmentVariables

if ($varsSet) {
    Write-Host "`nAll environment variables are set successfully!" -ForegroundColor Green
    Write-Host "You can now run .\deploy.ps1"
    
    # Optionally save to a .env file for future use
    $saveToFile = Read-Host "Would you like to save these variables to a .env file for future use? (y/n)"
    if ($saveToFile -eq "y") {
        @"
SLACK_WEBHOOK_URL=$env:SLACK_WEBHOOK_URL
GOOGLE_MAPS_API_KEY=$env:GOOGLE_MAPS_API_KEY
RSS_FEED_URL=$env:RSS_FEED_URL
"@ | Out-File -FilePath ".env" -Encoding UTF8
        Write-Host "Variables saved to .env file"
    }
} else {
    Write-Host "`nSome environment variables are still not set. Please run this script again." -ForegroundColor Red
}