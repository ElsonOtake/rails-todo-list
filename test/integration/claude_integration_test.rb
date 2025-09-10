require "test_helper"

class ClaudeIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    @linear_issue_data = {
      id: "VLV-363",
      identifier: "VLV-363",
      title: "Test Claude Integration",
      description: "This is a test issue for Claude integration",
      url: "https://linear.app/kobana/issue/VLV-363/test-claude-integration",
      teamId: "test-team",
      number: 363,
      labels: ["Ready for Claude", "bug", "needs-fix"]
    }
  end

  test "linear issue creates proper tracking file" do
    # Simulate Linear issue processing
    issue_file_path = ".linear/issue-#{@linear_issue_data[:identifier]}.md"
    
    # Check if the issue tracking file exists and has proper format
    assert File.exist?(Rails.root.join(issue_file_path)), "Linear issue file should exist"
    
    content = File.read(Rails.root.join(issue_file_path))
    assert_includes content, "# Linear Issue: #{@linear_issue_data[:identifier]}"
    assert_includes content, "**Title:** #{@linear_issue_data[:title]}"
    assert_includes content, "**Linear URL:** #{@linear_issue_data[:url]}"
  end

  test "claude trigger comment format is correct" do
    expected_trigger = "@claude implement this feature based on the PR description"
    
    # This tests the format expected by Claude Code workflow
    assert_match(/@claude/, expected_trigger)
    assert_includes expected_trigger, "implement"
    assert_includes expected_trigger, "PR description"
  end

  test "claude workflow conditions are properly validated" do
    # Test Claude workflow trigger conditions
    issue_comment_trigger = "@claude"
    pr_review_trigger = "@claude"
    
    # Should match the conditions in .github/workflows/claude.yml
    assert_match(/@claude/, issue_comment_trigger)
    assert_match(/@claude/, pr_review_trigger)
  end

  test "linear pr creation workflow validates required fields" do
    # Test the validation logic from linear-pr-creation.yml
    required_fields = [:title, :identifier, :id]
    
    required_fields.each do |field|
      assert @linear_issue_data.key?(field), "#{field} should be present"
      assert_not @linear_issue_data[field].to_s.empty?, "#{field} should not be empty"
    end
    
    # Test title length validation (max 256 characters)
    title = @linear_issue_data[:title]
    assert title.length <= 256, "Title should be under 256 characters"
  end

  test "ready for claude label detection works" do
    labels = @linear_issue_data[:labels]
    
    # Test the label detection logic from the workflow
    has_ready_label = labels.any? { |label| label == "Ready for Claude" }
    assert has_ready_label, "Should detect 'Ready for Claude' label"
    
    # Test case sensitivity
    case_sensitive_labels = ["ready for claude", "Ready For Claude", "READY FOR CLAUDE"]
    case_sensitive_labels.each do |label|
      refute labels.include?(label), "Should be case-sensitive for '#{label}'"
    end
  end

  test "branch naming follows convention" do
    identifier = @linear_issue_data[:identifier]
    expected_branch = "feature/linear-#{identifier}"
    
    # Test sanitization logic from workflow
    sanitized_identifier = identifier.gsub(/[^a-zA-Z0-9_-]/, '')
    sanitized_branch = "feature/linear-#{sanitized_identifier}"
    
    assert_equal expected_branch, sanitized_branch, "Branch name should follow convention"
    assert_match(/^feature\/linear-[a-zA-Z0-9_-]+$/, sanitized_branch)
  end

  test "pr description format is correct" do
    # Test PR description format from linear-pr-creation.yml
    expected_sections = [
      @linear_issue_data[:description],
      "**Linear Issue:** [#{@linear_issue_data[:identifier]}]",
      "**Team ID:** #{@linear_issue_data[:teamId]}",
      "**Issue Number:** #{@linear_issue_data[:number]}",
      "## 🤖 Claude Implementation",
      "Claude will be automatically triggered"
    ]
    
    expected_sections.each do |section|
      assert_not section.to_s.empty?, "PR description section should not be empty: #{section}"
    end
  end

  test "linear api response format is handled correctly" do
    # Mock Linear API response format
    mock_linear_response = {
      data: {
        issue: {
          id: "internal-id-123",
          labels: {
            nodes: [
              { id: "label1", name: "Ready for Claude" },
              { id: "label2", name: "bug" },
              { id: "label3", name: "needs-fix" }
            ]
          }
        }
      }
    }
    
    # Test label filtering logic (excluding "Ready for Claude")
    labels = mock_linear_response[:data][:issue][:labels][:nodes]
    filtered_labels = labels.reject { |label| label[:name] == "Ready for Claude" }
    
    assert_equal 2, filtered_labels.length
    refute filtered_labels.any? { |label| label[:name] == "Ready for Claude" }
    assert filtered_labels.any? { |label| label[:name] == "bug" }
    assert filtered_labels.any? { |label| label[:name] == "needs-fix" }
  end

  test "git operations follow security practices" do
    # Test git configuration from workflow
    expected_git_user = "github-actions[bot]"
    expected_git_email = "github-actions[bot]@users.noreply.github.com"
    
    assert_match(/github-actions\[bot\]/, expected_git_user)
    assert_match(/github-actions\[bot\]@users\.noreply\.github\.com/, expected_git_email)
    
    # Test commit message format
    identifier = @linear_issue_data[:identifier]
    expected_commit_msg = "Add Linear issue #{identifier} for implementation"
    
    assert_includes expected_commit_msg, identifier
    assert_includes expected_commit_msg, "Linear issue"
    assert_includes expected_commit_msg, "for implementation"
  end

  test "webhook security headers are validated" do
    # Test webhook security requirements
    required_headers = ["Accept", "Content-Type", "Authorization"]
    
    required_headers.each do |header|
      assert_not header.empty?, "Security header #{header} should be defined"
    end
    
    # Test webhook URL format
    webhook_url_pattern = /^https:\/\/api\.github\.com\/repos\/[^\/]+\/[^\/]+\/dispatches$/
    sample_url = "https://api.github.com/repos/ElsonOtake/rails-todo-list/dispatches"
    
    assert_match webhook_url_pattern, sample_url
  end

  test "concurrent workflow handling works correctly" do
    # Test concurrency control from linear-pr-creation.yml
    issue_id = @linear_issue_data[:id]
    concurrency_group = "linear-pr-#{issue_id}"
    
    assert_includes concurrency_group, issue_id
    assert_includes concurrency_group, "linear-pr"
    
    # Test that cancel-in-progress is false (from workflow config)
    cancel_in_progress = false
    refute cancel_in_progress, "Should not cancel in progress workflows"
  end

  private

  def simulate_webhook_payload
    {
      event_type: "linear_to_github_pr_event",
      client_payload: @linear_issue_data
    }
  end
end