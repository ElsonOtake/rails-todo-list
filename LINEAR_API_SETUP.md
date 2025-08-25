# Linear API Setup for GitHub Actions

This guide explains how to set up the Linear API integration to automatically remove the "Ready for Claude" label after processing.

## Prerequisites

1. Linear account with API access
2. GitHub repository with admin access

## Step 1: Generate Linear API Key

1. Go to Linear Settings: https://linear.app/settings/api
2. Click "Create new API key"
3. Give it a descriptive name like "GitHub Actions Integration"
4. Copy the generated API key (you won't be able to see it again)

## Step 2: Add API Key to GitHub Secrets

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `LINEAR_API_KEY`
5. Value: Paste your Linear API key
6. Click "Add secret"

## Step 3: How It Works

When the workflow runs after receiving a Linear webhook:

1. **PR Creation**: The workflow creates a PR for the Linear issue
2. **Label Removal**: After successful PR creation, the workflow:
   - Queries Linear for the issue's current labels
   - Filters out "Ready for Claude" label
   - Updates the issue with the remaining labels
   - Adds a comment to the Linear issue with PR details

## Step 4: Verify Integration

1. Create or update a Linear issue with the "Ready for Claude" label
2. Wait for n8n to trigger the GitHub workflow
3. Check that:
   - A PR is created in GitHub
   - The "Ready for Claude" label is removed from Linear
   - A comment is added to the Linear issue

## Troubleshooting

### API Key Not Working
- Ensure the API key has the necessary permissions (read/write issues and labels)
- Check that the secret name is exactly `LINEAR_API_KEY`

### Label Not Being Removed
- Check the workflow logs in GitHub Actions
- Verify the label name is exactly "Ready for Claude" (case-sensitive)
- Ensure the Linear API key secret is properly set

### Debugging
The workflow will output diagnostic information:
- The internal Linear issue ID
- Current labels on the issue
- API response for label update
- API response for comment creation

## Linear GraphQL API Reference

The workflow uses these Linear GraphQL queries:

1. **Get Issue Details**:
```graphql
query {
  issue(id: "ISSUE_ID") {
    id
    labels {
      nodes {
        id
        name
      }
    }
  }
}
```

2. **Update Issue Labels**:
```graphql
mutation {
  issueUpdate(id: "INTERNAL_ID", input: { labelIds: ["label1", "label2"] }) {
    success
    issue {
      labels {
        nodes {
          name
        }
      }
    }
  }
}
```

3. **Add Comment**:
```graphql
mutation {
  commentCreate(input: { issueId: "INTERNAL_ID", body: "Comment text" }) {
    success
  }
}
```

## Security Note

The Linear API key is stored securely in GitHub Secrets and is never exposed in logs or workflow files.