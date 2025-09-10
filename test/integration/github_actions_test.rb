require "test_helper"

class GithubActionsTest < ActionDispatch::IntegrationTest
  def setup
    @ci_workflow_path = Rails.root.join('.github/workflows/ci.yml')
    @claude_workflow_path = Rails.root.join('.github/workflows/claude.yml')
    @linear_workflow_path = Rails.root.join('.github/workflows/linear-pr-creation.yml')
    @review_workflow_path = Rails.root.join('.github/workflows/claude-code-review.yml')
  end

  test "ci workflow configuration is valid" do
    assert File.exist?(@ci_workflow_path), "CI workflow should exist"
    
    ci_content = File.read(@ci_workflow_path)
    
    # Test basic YAML structure expectations
    assert_includes ci_content, "name: CI"
    assert_includes ci_content, "on:"
    assert_includes ci_content, "jobs:"
    
    # Test required jobs exist
    assert_includes ci_content, "scan_ruby:"
    assert_includes ci_content, "scan_js:"
    assert_includes ci_content, "lint:"
    assert_includes ci_content, "test:"
    
    # Test security scanning is enabled
    assert_includes ci_content, "bin/brakeman"
    assert_includes ci_content, "bin/importmap audit"
    assert_includes ci_content, "bin/rubocop"
  end

  test "claude workflow triggers are properly configured" do
    assert File.exist?(@claude_workflow_path), "Claude workflow should exist"
    
    claude_content = File.read(@claude_workflow_path)
    
    # Test trigger events
    assert_includes claude_content, "issue_comment:"
    assert_includes claude_content, "pull_request_review_comment:"
    assert_includes claude_content, "issues:"
    assert_includes claude_content, "pull_request_review:"
    
    # Test trigger conditions
    assert_includes claude_content, "contains(github.event.comment.body, '@claude')"
    assert_includes claude_content, "contains(github.event.issue.body, '@claude')"
    
    # Test permissions
    assert_includes claude_content, "contents: read"
    assert_includes claude_content, "pull-requests: read"
    assert_includes claude_content, "issues: read"
    assert_includes claude_content, "actions: read"
  end

  test "linear workflow has proper validation steps" do
    assert File.exist?(@linear_workflow_path), "Linear workflow should exist"
    
    linear_content = File.read(@linear_workflow_path)
    
    # Test validation job exists
    assert_includes linear_content, "validate-inputs:"
    assert_includes linear_content, "check-conditions:"
    
    # Test required field validation
    assert_includes linear_content, "github.event.client_payload.title"
    assert_includes linear_content, "github.event.client_payload.identifier"
    assert_includes linear_content, "github.event.client_payload.id"
    
    # Test Ready for Claude label check
    assert_includes linear_content, 'Ready for Claude'
    
    # Test concurrency control
    assert_includes linear_content, "concurrency:"
    assert_includes linear_content, "linear-pr-"
  end

  test "workflow security permissions follow least privilege" do
    workflows = [@claude_workflow_path, @linear_workflow_path, @review_workflow_path]
    
    workflows.each do |workflow_path|
      next unless File.exist?(workflow_path)
      
      content = File.read(workflow_path)
      
      # Should explicitly define permissions
      assert_includes content, "permissions:", "#{File.basename(workflow_path)} should define permissions"
      
      # Should not use overly broad permissions
      refute_includes content, "permissions: write-all", "Should not use write-all permissions"
      refute_includes content, "contents: admin", "Should not use admin permissions"
    end
  end

  test "workflow environment variables are properly handled" do
    linear_content = File.read(@linear_workflow_path)
    
    # Test that secrets are referenced correctly
    assert_includes linear_content, "${{ secrets.LINEAR_API_KEY }}"
    assert_includes linear_content, "${{ secrets.CLAUDE_TRIGGER_TOKEN }}"
    
    # Test that secrets are not hardcoded
    refute_includes linear_content, "ghp_", "Should not contain hardcoded GitHub tokens"
    refute_includes linear_content, "lin_", "Should not contain hardcoded Linear tokens"
  end

  test "ci workflow handles test failures gracefully" do
    ci_content = File.read(@ci_workflow_path)
    
    # Test that artifacts are uploaded on failure
    assert_includes ci_content, "actions/upload-artifact"
    assert_includes ci_content, "if: failure()"
    assert_includes ci_content, "screenshots"
    
    # Test that database is properly set up for tests
    assert_includes ci_content, "postgres:"
    assert_includes ci_content, "DATABASE_URL:"
    assert_includes ci_content, "bin/rails db:test:prepare"
  end

  test "workflow dependencies are properly defined" do
    linear_content = File.read(@linear_workflow_path)
    
    # Test job dependencies
    assert_includes linear_content, "needs: validate-inputs"
    assert_includes linear_content, "needs: [validate-inputs, check-conditions]"
    
    # Test conditional execution
    assert_includes linear_content, "if: needs.validate-inputs.outputs.is_valid == 'true'"
  end

  test "claude code action version is up to date" do
    workflows = [@claude_workflow_path, @review_workflow_path]
    
    workflows.each do |workflow_path|
      next unless File.exist?(workflow_path)
      
      content = File.read(workflow_path)
      
      # Should use specific version, not latest
      assert_includes content, "anthropics/claude-code-action@beta", "Should use versioned action"
      refute_includes content, "@latest", "Should not use @latest tag"
    end
  end

  test "workflow error handling is implemented" do
    linear_content = File.read(@linear_workflow_path)
    
    # Test error handling in script steps
    assert_includes linear_content, "set -e", "Should exit on error"
    assert_includes linear_content, "if [ ", "Should have conditional error handling"
    
    # Test HTTP status code checking
    assert_includes linear_content, "http_code", "Should check HTTP status codes"
    assert_includes linear_content, '!= "200"', "Should validate successful responses"
  end

  test "workflow outputs are properly defined and used" do
    linear_content = File.read(@linear_workflow_path)
    
    # Test job outputs are defined
    assert_includes linear_content, "outputs:"
    assert_includes linear_content, "pr_number:"
    assert_includes linear_content, "pr_url:"
    
    # Test outputs are used by dependent jobs
    assert_includes linear_content, "needs.create-pr.outputs.pr_number"
    assert_includes linear_content, "needs.create-pr.outputs.pr_url"
  end

  test "workflow checkout uses secure configuration" do
    workflows = [@ci_workflow_path, @claude_workflow_path, @linear_workflow_path, @review_workflow_path]
    
    workflows.each do |workflow_path|
      next unless File.exist?(workflow_path)
      
      content = File.read(workflow_path)
      
      # Should use specific version of checkout action
      if content.include?("actions/checkout")
        assert_includes content, "actions/checkout@v5", "Should use specific checkout version"
      end
    end
  end

  test "workflow ruby setup is consistent" do
    ci_content = File.read(@ci_workflow_path)
    
    # Test Ruby setup configuration
    assert_includes ci_content, "ruby/setup-ruby@v1"
    assert_includes ci_content, "ruby-version: .ruby-version"
    assert_includes ci_content, "bundler-cache: true"
  end

  test "claude workflow bot permissions are configured" do
    claude_content = File.read(@claude_workflow_path)
    
    # Test that claude[bot] is allowed to trigger workflows
    assert_includes claude_content, "allowed_bots:"
    assert_includes claude_content, "claude[bot]"
  end

  test "workflow timeout configurations are reasonable" do
    workflows = [@ci_workflow_path, @linear_workflow_path]
    
    workflows.each do |workflow_path|
      next unless File.exist?(workflow_path)
      
      content = File.read(workflow_path)
      
      # If timeouts are specified, they should be reasonable
      if content.include?("timeout-minutes:")
        # Extract timeout values and validate they're reasonable (not too short, not too long)
        timeout_lines = content.scan(/timeout-minutes:\s*(\d+)/)
        timeout_lines.each do |timeout|
          timeout_value = timeout.first.to_i
          assert timeout_value >= 5, "Timeout should be at least 5 minutes"
          assert timeout_value <= 60, "Timeout should not exceed 60 minutes"
        end
      end
    end
  end

  test "workflow names and descriptions are clear" do
    workflows = {
      @ci_workflow_path => "CI",
      @claude_workflow_path => "Claude Code", 
      @linear_workflow_path => "Linear to GitHub PR Creation",
      @review_workflow_path => "Claude Code Review"
    }
    
    workflows.each do |workflow_path, expected_name|
      next unless File.exist?(workflow_path)
      
      content = File.read(workflow_path)
      assert_includes content, "name: #{expected_name}", "Workflow should have clear name"
    end
  end
end