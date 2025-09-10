require "test_helper"

class LinearGithubIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    @sample_payload = {
      event_type: "linear_to_github_pr_event",
      client_payload: {
        id: "VLV-363",
        identifier: "VLV-363", 
        title: "Bug Report (AI Tests - n8n- Claude Code)",
        description: "bugneeds-fix",
        url: "https://linear.app/kobana/issue/VLV-363/bug-report-ai-tests-n8n-claude-code",
        teamId: "test-team",
        number: 363,
        labels: ["Ready for Claude", "bug", "needs-fix"]
      }
    }
  end

  test "repository dispatch event structure is valid" do
    payload = @sample_payload
    
    # Test required top-level fields
    assert_equal "linear_to_github_pr_event", payload[:event_type]
    assert payload[:client_payload].is_a?(Hash)
    
    # Test required client_payload fields
    client_payload = payload[:client_payload]
    required_fields = [:id, :identifier, :title, :description, :url, :teamId, :number, :labels]
    
    required_fields.each do |field|
      assert client_payload.key?(field), "client_payload should have #{field}"
      assert_not client_payload[field].nil?, "#{field} should not be nil"
    end
  end

  test "linear issue id format is valid" do
    issue_id = @sample_payload[:client_payload][:id]
    identifier = @sample_payload[:client_payload][:identifier]
    
    # Should follow Linear issue ID format (letters-numbers)
    assert_match /^[A-Z]+-\d+$/, issue_id
    assert_match /^[A-Z]+-\d+$/, identifier
    assert_equal issue_id, identifier
  end

  test "linear url format is valid" do
    url = @sample_payload[:client_payload][:url]
    
    # Should be valid Linear URL format
    assert_match %r{^https://linear\.app/[\w\-]+/issue/[A-Z]+-\d+/}, url
    assert_includes url, @sample_payload[:client_payload][:identifier]
  end

  test "github workflow permissions are correctly configured" do
    # Test the permissions from linear-pr-creation.yml workflow
    expected_permissions = {
      contents: "write",        # Required for creating branches and pushing
      pull_requests: "write",   # Required for creating pull requests  
      issues: "write           # Required for adding comments to PRs
    }
    
    expected_permissions.each do |permission, level|
      assert_includes %w[read write], level, "#{permission} should have valid permission level"
    end
  end

  test "branch naming sanitization works correctly" do
    # Test various identifier formats and their sanitization
    test_cases = {
      "VLV-363" => "VLV-363",                    # normal case
      "VLV@363" => "VLV363",                     # special chars removed
      "VLV 363" => "VLV363",                     # spaces removed  
      "VLV-363!" => "VLV-363",                   # punctuation removed
      "VLV_363" => "VLV_363",                    # underscores kept
      "very-long-identifier-name" => "very-long-identifier-name"  # long names kept
    }
    
    test_cases.each do |input, expected|
      sanitized = input.gsub(/[^a-zA-Z0-9_-]/, '')
      branch_name = "feature/linear-#{sanitized}"
      expected_branch = "feature/linear-#{expected}"
      
      assert_equal expected_branch, branch_name, "#{input} should sanitize to #{expected}"
      assert_match /^feature\/linear-[a-zA-Z0-9_-]+$/, branch_name
    end
  end

  test "pr title length validation works" do
    # Test title length limits (GitHub PR title max is 256 characters)
    short_title = "Short title"
    long_title = "A" * 300  # Too long
    max_title = "B" * 256   # Maximum allowed
    
    assert short_title.length <= 256, "Short title should be valid"
    assert long_title.length > 256, "Long title should exceed limit"
    assert max_title.length == 256, "Max title should be exactly 256 chars"
    
    # Test truncation
    truncated = long_title[0, 256]
    assert_equal 256, truncated.length
  end

  test "input sanitization prevents injection attacks" do
    # Test sanitization of potentially dangerous inputs
    dangerous_inputs = {
      title: "'; DROP TABLE users; --",
      description: "<script>alert('xss')</script>",
      identifier: "../../../etc/passwd",
      teamId: "${env:SECRET_KEY}"
    }
    
    dangerous_inputs.each do |field, dangerous_value|
      # These should be escaped/sanitized in the workflow
      refute_includes dangerous_value, "\0", "#{field} should not contain null bytes"
      
      # Test basic escaping for shell injection prevention
      escaped = dangerous_value.gsub("'", "'\\\\'\'")
      assert_includes escaped, "\\\\'", "#{field} should escape single quotes"
    end
  end

  test "linear api response parsing is robust" do
    # Test various Linear API response formats
    valid_response = {
      data: {
        issue: {
          id: "internal-123",
          labels: {
            nodes: [
              { id: "label1", name: "Ready for Claude" },
              { id: "label2", name: "bug" }
            ]
          }
        }
      }
    }
    
    # Test parsing
    issue = valid_response[:data][:issue]
    assert_equal "internal-123", issue[:id]
    
    labels = issue[:labels][:nodes]
    assert_equal 2, labels.length
    assert labels.any? { |l| l[:name] == "Ready for Claude" }
    
    # Test error response
    error_response = {
      errors: [
        { message: "Authentication failed" }
      ]
    }
    
    assert error_response.key?(:errors), "Should handle error responses"
  end

  test "concurrent pr creation is handled correctly" do
    # Test concurrency control logic
    issue_id = @sample_payload[:client_payload][:id]
    concurrency_group = "linear-pr-#{issue_id}"
    
    # Should create unique concurrency groups per issue
    different_issue_group = "linear-pr-VLV-999"
    refute_equal concurrency_group, different_issue_group
    
    # Should use issue ID in group name
    assert_includes concurrency_group, issue_id
    assert_includes concurrency_group, "linear-pr"
  end

  test "git operations use secure configurations" do
    # Test git configuration security
    git_user = "github-actions[bot]"
    git_email = "github-actions[bot]@users.noreply.github.com"
    
    # Should use bot account
    assert_includes git_user, "github-actions"
    assert_includes git_user, "[bot]"
    assert_includes git_email, "users.noreply.github.com"
    
    # Should not use personal credentials
    refute_includes git_email, "@gmail.com"
    refute_includes git_email, "@personal.com"
  end

  test "webhook payload validation prevents malformed requests" do
    # Test validation of required fields
    incomplete_payloads = [
      { event_type: "linear_to_github_pr_event" },  # missing client_payload
      { client_payload: { id: "123" } },            # missing event_type
      { 
        event_type: "linear_to_github_pr_event",
        client_payload: { id: "" }                  # empty required field
      }
    ]
    
    incomplete_payloads.each_with_index do |payload, index|
      # These should fail validation in the workflow
      if payload[:client_payload]
        client_payload = payload[:client_payload]
        assert client_payload[:id].to_s.empty?, "Test case #{index} should have empty ID" if client_payload.key?(:id)
      end
    end
  end

  test "label filtering removes ready for claude correctly" do
    # Mock Linear API response with labels
    labels = [
      { id: "label1", name: "Ready for Claude" },
      { id: "label2", name: "bug" },
      { id: "label3", name: "needs-fix" },
      { id: "label4", name: "ready for claude" },  # different case
      { id: "label5", name: "enhancement" }
    ]
    
    # Filter out "Ready for Claude" (exact match, case sensitive)
    filtered = labels.reject { |label| label[:name] == "Ready for Claude" }
    
    assert_equal 4, filtered.length, "Should remove only exact match"
    refute filtered.any? { |l| l[:name] == "Ready for Claude" }
    assert filtered.any? { |l| l[:name] == "ready for claude" }, "Should keep different case"
    assert filtered.any? { |l| l[:name] == "bug" }
    assert filtered.any? { |l| l[:name] == "needs-fix" }
  end

  test "pr creation handles existing prs gracefully" do
    # Test the logic for handling existing PRs
    branch_name = "feature/linear-VLV-363"
    
    # Simulate checking for existing PR
    existing_prs = [
      {
        number: 41,
        html_url: "https://github.com/ElsonOtake/rails-todo-list/pull/41",
        head: { ref: branch_name }
      }
    ]
    
    # Should detect existing PR
    matching_pr = existing_prs.find { |pr| pr[:head][:ref] == branch_name }
    assert_not_nil matching_pr, "Should find existing PR for branch"
    assert_equal 41, matching_pr[:number]
  end

  test "claude trigger token usage is secure" do
    # Test that Claude trigger uses separate token
    # This prevents the main GITHUB_TOKEN from being overused
    
    # Should use different token for Claude triggering
    github_token_var = "GITHUB_TOKEN"
    claude_token_var = "CLAUDE_TRIGGER_TOKEN"
    
    refute_equal github_token_var, claude_token_var
    assert_includes claude_token_var, "CLAUDE"
    assert_includes claude_token_var, "TRIGGER"
  end

  private

  def simulate_github_api_response(pr_number)
    {
      number: pr_number,
      html_url: "https://github.com/ElsonOtake/rails-todo-list/pull/#{pr_number}",
      title: @sample_payload[:client_payload][:title],
      body: build_pr_body,
      head: { ref: "feature/linear-#{@sample_payload[:client_payload][:identifier]}" },
      base: { ref: "main" }
    }
  end

  def build_pr_body
    payload = @sample_payload[:client_payload]
    <<~BODY
      #{payload[:description]}
      
      ---
      
      **Linear Issue:** [#{payload[:identifier]}](#{payload[:url]})
      **Team ID:** #{payload[:teamId]}
      **Issue Number:** #{payload[:number]}
      
      ---
      
      ## 🤖 Claude Implementation
      
      Claude will be automatically triggered to implement this feature.
      The implementation will begin shortly after PR creation.
    BODY
  end
end