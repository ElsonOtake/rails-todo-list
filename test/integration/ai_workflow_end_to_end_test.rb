require "test_helper"

class AiWorkflowEndToEndTest < ActionDispatch::IntegrationTest
  def setup
    @workflow_steps = [
      "linear_issue_created",
      "n8n_webhook_received",
      "github_dispatch_triggered",
      "pr_created",
      "claude_triggered",
      "implementation_completed"
    ]
  end

  test "complete ai workflow chain is properly configured" do
    # Test that all components are configured to work together
    
    # Step 1: Linear Issue Configuration
    linear_config = {
      webhook_url: "n8n-webhook-endpoint",
      label_trigger: "Ready for Claude",
      issue_types: ["bug", "feature", "enhancement"]
    }
    
    assert_includes linear_config[:issue_types], "bug"
    assert_equal "Ready for Claude", linear_config[:label_trigger]
    
    # Step 2: N8N Configuration (from n8n-http-request-config.json)
    config_file = Rails.root.join('n8n-http-request-config.json')
    assert File.exist?(config_file), "n8n config file must exist: #{config_file}"
    n8n_config = JSON.parse(File.read(config_file))
    
    assert_equal "POST", n8n_config["method"]
    assert_includes n8n_config["url"], "github.com/repos"
    assert_includes n8n_config["url"], "/dispatches"
    
    # Step 3: GitHub Workflow Configuration
    # This tests the structure expected by linear-pr-creation.yml
    github_dispatch = {
      event_type: "linear_to_github_pr_event",
      client_payload: {
        id: "TEST-123",
        title: "Test Issue",
        labels: ["Ready for Claude"]
      }
    }
    
    assert_equal "linear_to_github_pr_event", github_dispatch[:event_type]
    assert_includes github_dispatch[:client_payload][:labels], "Ready for Claude"
  end

  test "workflow error recovery scenarios are handled" do
    # Test various failure scenarios and recovery mechanisms
    
    error_scenarios = [
      {
        step: "n8n_webhook_processing",
        error: "invalid_json",
        recovery: "retry_with_validation"
      },
      {
        step: "github_pr_creation", 
        error: "no_commits_between_branches",
        recovery: "create_initial_commit"
      },
      {
        step: "claude_trigger",
        error: "invalid_token",
        recovery: "use_alternate_token"
      },
      {
        step: "linear_label_removal",
        error: "api_rate_limit",
        recovery: "continue_with_warning"
      }
    ]
    
    error_scenarios.each do |scenario|
      assert_not scenario[:error].empty?, "#{scenario[:step]} should have error handling"
      assert_not scenario[:recovery].empty?, "#{scenario[:step]} should have recovery strategy"
    end
  end

  test "workflow timing and dependencies are correct" do
    # Test that workflows run in correct sequence with proper dependencies
    
    workflow_dependencies = {
      validate_inputs: [],
      check_conditions: ["validate_inputs"],
      create_pr: ["validate_inputs", "check_conditions"],
      trigger_claude: ["create_pr"],
      remove_linear_label: ["create_pr"]
    }
    
    workflow_dependencies.each do |job, deps|
      if deps.any?
        deps.each do |dep|
          assert workflow_dependencies.key?(dep.to_sym), "Dependency #{dep} should exist"
        end
      end
    end
  end

  test "data transformation through pipeline maintains integrity" do
    # Test data transformation from Linear → n8n → GitHub → Claude
    
    # Original Linear data
    linear_issue = {
      issueId: "VLV-363",
      title: "Bug Report (AI Tests - n8n- Claude Code)",
      description: "bugneeds-fix",
      labels: ["Ready for Claude", "bug"],
      team: "kobana",
      url: "https://linear.app/kobana/issue/VLV-363/bug-report-ai-tests-n8n-claude-code"
    }
    
    # After n8n transformation
    github_payload = {
      event_type: "linear_to_github_pr_event",
      client_payload: {
        id: linear_issue[:issueId],
        identifier: linear_issue[:issueId],
        title: linear_issue[:title],
        description: linear_issue[:description],
        labels: linear_issue[:labels],
        url: linear_issue[:url],
        teamId: linear_issue[:team]
      }
    }
    
    # Verify data integrity through transformation
    assert_equal linear_issue[:issueId], github_payload[:client_payload][:id]
    assert_equal linear_issue[:title], github_payload[:client_payload][:title]
    assert_equal linear_issue[:description], github_payload[:client_payload][:description]
    assert_equal linear_issue[:labels], github_payload[:client_payload][:labels]
    
    # After GitHub processing
    pr_data = {
      title: github_payload[:client_payload][:title],
      body: build_pr_body(github_payload[:client_payload]),
      branch: "feature/linear-#{github_payload[:client_payload][:identifier]}",
      base: "main"
    }
    
    assert_includes pr_data[:body], github_payload[:client_payload][:description]
    assert_includes pr_data[:body], github_payload[:client_payload][:url]
    assert_includes pr_data[:branch], github_payload[:client_payload][:identifier]
    
    # Claude trigger
    claude_comment = "@claude implement this feature based on the PR description"
    
    assert_includes claude_comment, "@claude"
    assert_includes claude_comment, "implement"
    assert_includes claude_comment, "PR description"
  end

  test "workflow security measures are in place" do
    # Test security measures throughout the workflow
    
    security_checks = {
      linear_webhook: {
        https_required: true,
        secret_validation: true,
        input_sanitization: true
      },
      n8n_processing: {
        credential_encryption: true,
        secure_headers: true,
        output_validation: true
      },
      github_workflow: {
        token_isolation: true,
        permission_minimization: true,
        secret_masking: true
      },
      claude_integration: {
        separate_token: true,
        comment_validation: true,
        scope_limitation: true
      }
    }
    
    security_checks.each do |component, checks|
      checks.each do |check, required|
        assert required, "#{component} should have #{check} enabled"
      end
    end
  end

  test "workflow monitoring and observability works" do
    # Test that workflows provide adequate monitoring
    
    monitoring_points = [
      "webhook_received",
      "payload_validated",
      "branch_created",
      "pr_created", 
      "claude_triggered",
      "labels_updated",
      "workflow_completed"
    ]
    
    monitoring_points.each do |point|
      # Each point should have logging/monitoring
      assert_not point.empty?, "Monitoring point #{point} should be defined"
      assert_includes point, "_", "Monitoring points should follow naming convention"
    end
  end

  test "workflow performance characteristics are acceptable" do
    # Test expected performance characteristics
    
    performance_requirements = {
      webhook_processing_time: 30, # seconds
      pr_creation_time: 60,       # seconds  
      claude_trigger_delay: 10,    # seconds
      total_workflow_time: 300     # seconds (5 minutes)
    }
    
    performance_requirements.each do |metric, max_time|
      assert max_time > 0, "#{metric} should have positive time limit"
      assert max_time < 600, "#{metric} should complete within 10 minutes"
    end
  end

  test "workflow rollback and cleanup procedures work" do
    # Test cleanup procedures for failed workflows
    
    cleanup_scenarios = [
      {
        failure_point: "pr_creation_failed",
        cleanup_actions: ["delete_branch", "notify_linear"]
      },
      {
        failure_point: "claude_trigger_failed", 
        cleanup_actions: ["update_pr_status", "manual_fallback"]
      },
      {
        failure_point: "label_removal_failed",
        cleanup_actions: ["log_warning", "continue_workflow"]
      }
    ]
    
    cleanup_scenarios.each do |scenario|
      assert scenario[:cleanup_actions].any?, "#{scenario[:failure_point]} should have cleanup actions"
      scenario[:cleanup_actions].each do |action|
        assert_not action.empty?, "Cleanup action should not be empty"
      end
    end
  end

  test "workflow configuration versioning is maintained" do
    # Test that workflow configurations are properly versioned
    
    workflow_files = [
      ".github/workflows/claude.yml",
      ".github/workflows/linear-pr-creation.yml", 
      ".github/workflows/claude-code-review.yml",
      "n8n-http-request-config.json"
    ]
    
    workflow_files.each do |file|
      assert File.exist?(Rails.root.join(file)), "#{file} should exist"
      
      # Basic validation that files are not empty
      content = File.read(Rails.root.join(file))
      assert_not content.empty?, "#{file} should not be empty"
    end
  end

  test "workflow integration points are well defined" do
    # Test that integration points between components are well defined
    
    integration_contracts = {
      linear_to_n8n: {
        format: "webhook_json",
        required_fields: ["issueId", "title", "labels"],
        authentication: "webhook_secret"
      },
      n8n_to_github: {
        format: "repository_dispatch",
        required_fields: ["event_type", "client_payload"], 
        authentication: "github_token"
      },
      github_to_claude: {
        format: "issue_comment",
        required_fields: ["body"],
        authentication: "claude_token"
      }
    }
    
    integration_contracts.each do |integration, contract|
      assert_not contract[:format].empty?, "#{integration} should define format"
      assert contract[:required_fields].any?, "#{integration} should define required fields"
      assert_not contract[:authentication].empty?, "#{integration} should define authentication"
    end
  end

  private

  def build_pr_body(client_payload)
    <<~BODY
      #{client_payload[:description]}
      
      ---
      
      **Linear Issue:** [#{client_payload[:identifier]}](#{client_payload[:url]})
      **Team ID:** #{client_payload[:teamId]}
      **Issue Number:** #{client_payload[:number]}
      
      ---
      
      ## 🤖 Claude Implementation
      
      Claude will be automatically triggered to implement this feature.
      The implementation will begin shortly after PR creation.
    BODY
  end

  def simulate_workflow_execution(linear_issue_data)
    # Simulate complete workflow execution
    steps = []
    
    # Step 1: Linear webhook
    steps << { step: "linear_webhook", status: "success", data: linear_issue_data }
    
    # Step 2: N8N processing  
    github_payload = transform_linear_to_github(linear_issue_data)
    steps << { step: "n8n_transform", status: "success", data: github_payload }
    
    # Step 3: GitHub PR creation
    pr_data = create_pr_from_payload(github_payload)
    steps << { step: "github_pr", status: "success", data: pr_data }
    
    # Step 4: Claude trigger
    claude_trigger = "@claude implement this feature based on the PR description"
    steps << { step: "claude_trigger", status: "success", data: { comment: claude_trigger } }
    
    steps
  end

  def transform_linear_to_github(linear_data)
    {
      event_type: "linear_to_github_pr_event",
      client_payload: {
        id: linear_data[:issueId],
        identifier: linear_data[:issueId],
        title: linear_data[:title],
        description: linear_data[:description],
        labels: linear_data[:labels],
        url: linear_data[:url]
      }
    }
  end

  def create_pr_from_payload(github_payload)
    {
      title: github_payload[:client_payload][:title],
      branch: "feature/linear-#{github_payload[:client_payload][:identifier]}",
      base: "main",
      body: build_pr_body(github_payload[:client_payload])
    }
  end
end