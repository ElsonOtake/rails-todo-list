# Linear to Claude Code Integration

This repository includes an automated workflow that monitors Linear issues and initiates refactoring tasks when issues are tagged with "ready for Claude".

## Overview

The integration creates a seamless workflow:
1. Create a Linear card with refactoring instructions
2. Add the "ready for Claude" label
3. GitHub Actions automatically creates a PR with instructions
4. Use Claude Code to perform the refactoring
5. Commit changes to the PR

## Setup Instructions

### 1. Linear API Setup

1. Go to [Linear Settings](https://linear.app/settings/api)
2. Create a new Personal API Key
3. Copy the API key

### 2. GitHub Repository Secrets

Add the following secrets to your GitHub repository:

1. Go to Settings → Secrets and variables → Actions
2. Add these secrets:
   - `LINEAR_API_KEY`: Your Linear Personal API Key
   - `SLACK_WEBHOOK_URL`: (Optional) Slack webhook for notifications

### 3. Linear Label Configuration

In your Linear workspace:

1. Go to Settings → Labels
2. Create a new label called "ready for Claude"
   - Color: Choose a distinctive color (e.g., purple)
   - Description: "Issue is ready for automated refactoring with Claude Code"

### 4. GitHub Labels

The workflow will automatically use these labels on PRs:
- `refactoring`
- `linear-integration`
- `needs-claude`

Create them in your repository or they'll be created automatically.

## Usage

### Creating a Refactoring Task

1. **In Linear:**
   - Create a new issue
   - Add a clear title (e.g., "Refactor Todo model for better performance")
   - In the description, specify:
     - What needs to be refactored
     - Why it needs refactoring
     - Any specific requirements or constraints
   - Add the "ready for Claude" label

2. **Automated Process:**
   - GitHub Actions runs hourly (or on manual trigger)
   - Detects issues with "ready for Claude" label
   - Creates a new branch
   - Generates refactoring instructions
   - Opens a PR with all details

3. **Using Claude Code:**
   - Pull the created branch locally
   - Open the repository in Claude Code
   - Review `refactoring-instructions.md`
   - Perform the refactoring
   - Commit and push changes

### Manual Trigger

You can manually trigger the workflow:

```bash
gh workflow run linear-claude-refactor.yml -f linear_issue_id=<ISSUE_ID>
```

## Example Linear Issue

```markdown
Title: Optimize database queries in TodosController

Description:
The TodosController#index action is making multiple database queries that could be optimized.

Requirements:
- Reduce N+1 queries
- Add proper eager loading
- Implement query caching where appropriate
- Maintain existing functionality
- Add performance tests

Acceptance Criteria:
- Page load time reduced by at least 30%
- All existing tests pass
- New performance tests added
```

## Workflow Features

### Automatic PR Creation
- Creates a dedicated branch for each Linear issue
- Opens a PR with detailed instructions
- Links back to the Linear issue

### Refactoring Instructions
The workflow generates a `refactoring-instructions.md` file with:
- Issue details from Linear
- General refactoring guidelines
- Rails-specific best practices
- Success criteria

### Claude Task File
Creates `.claude-task.json` with structured data for Claude Code:
- Task type and metadata
- Focus areas and constraints
- Timestamp and branch information

### Linear Updates
- Removes "ready for Claude" label after processing
- Adds a comment with PR link
- Can update issue status (configure as needed)

### Notifications
- Optional Slack notifications
- GitHub PR notifications
- Linear comment notifications

## Best Practices

### Writing Good Linear Issues

1. **Clear Title**: Be specific about what needs refactoring
2. **Detailed Description**: Include:
   - Current problems
   - Desired outcomes
   - Technical constraints
   - Performance targets

3. **Acceptance Criteria**: Define success metrics

### Refactoring Guidelines

1. **Start Small**: Focus on one area at a time
2. **Test First**: Ensure tests exist before refactoring
3. **Incremental Changes**: Make reviewable commits
4. **Document Changes**: Update comments and docs

### Review Process

1. Review generated instructions
2. Perform refactoring in Claude Code
3. Run all tests locally
4. Update PR description with changes made
5. Request review from team

## Troubleshooting

### Workflow Not Triggering

1. Check Linear API key is valid
2. Verify "ready for Claude" label exists
3. Check GitHub Actions logs
4. Ensure workflow file is in main branch

### PR Creation Fails

1. Check GitHub token permissions
2. Verify branch naming conflicts
3. Review Actions logs for errors

### Linear Not Updating

1. Verify API key has write permissions
2. Check Linear issue ID format
3. Review GraphQL query errors

## Advanced Configuration

### Customizing Check Frequency

Edit the cron schedule in `.github/workflows/linear-claude-refactor.yml`:

```yaml
schedule:
  - cron: '0 * * * *'  # Every hour
  # - cron: '*/15 * * * *'  # Every 15 minutes
  # - cron: '0 9 * * 1-5'  # Weekdays at 9 AM
```

### Adding Custom Labels

Modify the GraphQL query to check for different labels:

```javascript
filter: { 
  labels: { 
    name: { 
      in: ["ready for Claude", "needs-refactoring", "technical-debt"] 
    } 
  }
}
```

### Customizing Refactoring Instructions

Edit the template in the workflow file to add project-specific guidelines.

## Security Considerations

- API keys are stored as GitHub secrets
- Workflow has minimal permissions
- PRs require manual review
- No automatic merging

## Support

For issues or questions:
1. Check the workflow logs in GitHub Actions
2. Review Linear API documentation
3. Consult Claude Code documentation
4. Open an issue in this repository