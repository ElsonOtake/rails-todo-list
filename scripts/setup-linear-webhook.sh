#!/bin/bash

# Setup Linear Webhook for GitHub Integration
# This script configures a Linear webhook to trigger GitHub Actions

set -e

echo "Linear Webhook Setup Script"
echo "=========================="
echo ""

# Check for required environment variables
if [ -z "$LINEAR_API_KEY" ]; then
    echo "Error: LINEAR_API_KEY environment variable is not set"
    echo "Please set it with: export LINEAR_API_KEY=your_api_key"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set"
    echo "Please set it with: export GITHUB_TOKEN=your_github_token"
    exit 1
fi

# Get repository information
REPO_OWNER=$(git remote get-url origin | sed -n 's/.*github.com[:/]\([^/]*\).*/\1/p')
REPO_NAME=$(git remote get-url origin | sed -n 's/.*github.com[:/][^/]*\/\(.*\)\.git/\1/p')

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
    echo "Error: Could not determine repository owner and name"
    echo "Please ensure you're in a git repository with a GitHub remote"
    exit 1
fi

echo "Repository: $REPO_OWNER/$REPO_NAME"
echo ""

# GitHub webhook URL for repository_dispatch events
WEBHOOK_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/dispatches"

echo "Creating Linear webhook..."
echo ""

# Create the webhook using Linear API
RESPONSE=$(curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation CreateWebhook($input: WebhookCreateInput!) { webhookCreate(input: $input) { success webhook { id url enabled } } }",
    "variables": {
      "input": {
        "url": "'"$WEBHOOK_URL"'",
        "resourceTypes": ["Issue", "Comment", "Label"],
        "enabled": true,
        "secret": "'"$GITHUB_TOKEN"'",
        "label": "GitHub Actions - Claude Refactoring"
      }
    }
  }')

# Check if webhook was created successfully
SUCCESS=$(echo $RESPONSE | jq -r '.data.webhookCreate.success')

if [ "$SUCCESS" == "true" ]; then
    WEBHOOK_ID=$(echo $RESPONSE | jq -r '.data.webhookCreate.webhook.id')
    echo "✅ Webhook created successfully!"
    echo "Webhook ID: $WEBHOOK_ID"
    echo ""
    echo "The webhook will trigger when:"
    echo "  - Issues are created or updated"
    echo "  - Labels are added or removed"
    echo "  - Comments are added to issues"
    echo ""
    echo "Next steps:"
    echo "1. Add the 'ready for Claude' label in Linear"
    echo "2. Create an issue and tag it with 'ready for Claude'"
    echo "3. The GitHub Action will automatically create a refactoring PR"
else
    echo "❌ Failed to create webhook"
    echo "Response: $RESPONSE"
    exit 1
fi

echo ""
echo "Creating webhook proxy configuration..."

# Create a simple webhook proxy configuration file
cat > webhook-config.json << EOF
{
  "webhook_id": "$WEBHOOK_ID",
  "repository": "$REPO_OWNER/$REPO_NAME",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "linear_events": ["Issue.create", "Issue.update", "Label.create", "Label.delete"],
  "github_action": "linear-webhook-handler.yml",
  "trigger_label": "ready for Claude"
}
EOF

echo "Configuration saved to webhook-config.json"
echo ""
echo "Setup complete! 🎉"