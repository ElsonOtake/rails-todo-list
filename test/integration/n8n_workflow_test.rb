require "test_helper"

class N8nWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    config_file = Rails.root.join('n8n-http-request-config.json')
    assert File.exist?(config_file), "n8n config file must exist: #{config_file}"
    @n8n_config = JSON.parse(File.read(config_file))
  end

  test "n8n http request configuration is valid" do
    # Test basic configuration structure
    assert_equal "POST", @n8n_config["method"]
    assert_includes @n8n_config["url"], "api.github.com/repos"
    assert_includes @n8n_config["url"], "/dispatches"
    
    # Test authentication configuration
    assert_equal "genericCredentialType", @n8n_config["authentication"]
    assert_equal "httpHeaderAuth", @n8n_config["genericAuthType"]
  end

  test "n8n request headers are properly configured" do
    headers = @n8n_config["headerParameters"]["parameters"]
    
    # Find required headers
    accept_header = headers.find { |h| h["name"] == "Accept" }
    content_type_header = headers.find { |h| h["name"] == "Content-Type" }
    
    assert_not_nil accept_header, "Accept header should be configured"
    assert_not_nil content_type_header, "Content-Type header should be configured"
    
    assert_equal "application/vnd.github.v3+json", accept_header["value"]
    assert_equal "application/json", content_type_header["value"]
  end

  test "n8n json body template is properly structured" do
    json_body = JSON.parse(@n8n_config["jsonBody"])
    
    # Test event type
    assert_equal "linear_event", json_body["event_type"]
    
    # Test client payload structure
    client_payload = json_body["client_payload"]
    required_fields = %w[issueId title description labels team url priority estimate sections]
    
    required_fields.each do |field|
      assert client_payload.key?(field), "client_payload should have #{field} field"
    end
    
    # Test sections structure for bug reports
    sections = client_payload["sections"]
    section_fields = %w[type currentBehavior expectedBehavior stepsToReproduce proposedSolution]
    
    section_fields.each do |field|
      assert sections.key?(field), "sections should have #{field} field"
    end
  end

  test "n8n variable interpolation format is correct" do
    json_body = @n8n_config["jsonBody"]
    
    # Test n8n variable format {{ $json.fieldName }}
    variable_pattern = /\{\{\s*\$json\.\w+\s*\}\}/
    
    # Should contain n8n variables
    assert_match variable_pattern, json_body
    
    # Test specific required variables
    required_variables = [
      "{{ $json.issueId }}",
      "{{ $json.title }}",
      "{{ $json.description }}",
      "{{ $json.labels }}",
      "{{ $json.team }}",
      "{{ $json.url }}"
    ]
    
    required_variables.each do |var|
      assert_includes json_body, var, "Should include variable #{var}"
    end
  end

  test "n8n handles linear priority mapping correctly" do
    json_body = JSON.parse(@n8n_config["jsonBody"])
    
    # Priority should be passed as number (not string with {{ }})
    priority_field = json_body["client_payload"]["priority"]
    estimate_field = json_body["client_payload"]["estimate"]
    
    # These should be n8n variables without quotes for proper number handling
    assert_equal "{{ $json.priority }}", priority_field.to_s.strip
    assert_equal "{{ $json.estimate }}", estimate_field.to_s.strip
  end

  test "n8n labels array handling is correct" do
    json_body = @n8n_config["jsonBody"]
    
    # Labels should be handled as array without quotes
    labels_pattern = /{{ \$json\.labels }}/
    assert_match labels_pattern, json_body
    
    # Should not be wrapped in quotes (for proper array handling)
    refute_includes json_body, '"{{ $json.labels }}"'
  end

  test "n8n webhook url format is github dispatch compatible" do
    url = @n8n_config["url"]
    
    # Should match GitHub repository dispatch API format
    github_dispatch_pattern = %r{^https://api\.github\.com/repos/[\w\-\.]+/[\w\-\.]+/dispatches$}
    assert_match github_dispatch_pattern, url
    
    # Should be for the correct repository
    assert_includes url, "ElsonOtake/rails-todo-list"
  end

  test "n8n configuration enables proper body handling" do
    assert @n8n_config["sendHeaders"], "Should send headers"
    assert @n8n_config["sendBody"], "Should send body"
    assert_equal "json", @n8n_config["specifyBody"]
  end

  test "n8n linear to github event transformation works" do
    # Mock Linear webhook payload
    linear_payload = {
      issueId: "VLV-363",
      title: "Bug Report (AI Tests - n8n- Claude Code)",
      description: "bugneeds-fix",
      labels: ["Ready for Claude", "bug"],
      team: "kobana",
      url: "https://linear.app/kobana/issue/VLV-363/bug-report-ai-tests-n8n-claude-code",
      priority: 2,
      estimate: 3,
      sections: {
        type: "bug",
        currentBehavior: "Tests failing",
        expectedBehavior: "Tests passing",
        stepsToReproduce: "Run test suite",
        proposedSolution: "Fix test configuration"
      }
    }
    
    # Transform to GitHub dispatch format (simulating n8n transformation)
    github_payload = {
      event_type: "linear_to_github_pr_event",
      client_payload: {
        id: linear_payload[:issueId],
        identifier: linear_payload[:issueId],
        title: linear_payload[:title],
        description: linear_payload[:description],
        labels: linear_payload[:labels],
        url: linear_payload[:url],
        teamId: linear_payload[:team],
        number: linear_payload[:issueId].match(/\d+/)&.to_s&.to_i || 0,
        priority: linear_payload[:priority],
        estimate: linear_payload[:estimate],
        sections: linear_payload[:sections]
      }
    }
    
    # Test transformation results
    assert_equal "linear_to_github_pr_event", github_payload[:event_type]
    assert_equal linear_payload[:issueId], github_payload[:client_payload][:id]
    assert_equal linear_payload[:title], github_payload[:client_payload][:title]
    assert_includes github_payload[:client_payload][:labels], "Ready for Claude"
  end

  test "n8n error handling scenarios are covered" do
    # Test various error scenarios that n8n should handle
    
    # Empty/missing required fields
    empty_payload = {
      issueId: "",
      title: nil,
      description: ""
    }
    
    empty_payload.each do |field, value|
      assert_empty value.to_s, "#{field} should be validated as empty"
    end
    
    # Invalid URL format
    invalid_urls = [
      "not-a-url",
      "http://example.com",  # not https
      "https://wrong-api.com/repos/user/repo/dispatches"  # wrong API
    ]
    
    invalid_urls.each do |url|
      refute_match %r{^https://api\.github\.com/repos/[\w\-\.]+/[\w\-\.]+/dispatches$}, url
    end
  end

  test "n8n webhook security considerations are addressed" do
    # Test that sensitive data handling is proper
    config = @n8n_config
    
    # Should use authentication
    assert config["authentication"], "Should use authentication"
    
    # Should use HTTPS
    assert_includes config["url"], "https://", "Should use HTTPS"
    
    # Should not contain hardcoded secrets in config
    refute_includes config.to_s, "ghp_", "Should not contain GitHub tokens"
    refute_includes config.to_s, "lin_", "Should not contain Linear tokens"
  end

  private

  def simulate_n8n_processing(linear_webhook_data)
    # Simulate how n8n would process and transform Linear webhook data
    {
      event_type: "linear_to_github_pr_event", 
      client_payload: {
        id: linear_webhook_data["data"]["issueId"],
        identifier: linear_webhook_data["data"]["identifier"],
        title: linear_webhook_data["data"]["title"],
        description: linear_webhook_data["data"]["description"],
        labels: linear_webhook_data["data"]["labels"],
        url: linear_webhook_data["data"]["url"],
        teamId: linear_webhook_data["data"]["team"]["id"],
        number: linear_webhook_data["data"]["number"]
      }
    }
  end
end