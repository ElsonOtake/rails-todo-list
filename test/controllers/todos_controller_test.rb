require "test_helper"

class TodosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @todo = todos(:one)
  end

  test "should get index" do
    get todos_url
    assert_response :success
  end

  test "should get new" do
    get new_todo_url
    assert_response :success
  end

  test "should create todo" do
    assert_difference("Todo.count") do
      post todos_url, params: { todo: { 
        title: "New Todo", 
        description: "Test description", 
        priority: "low", 
        completed: false 
      } }
    end

    assert_redirected_to todos_url
  end

  test "should get edit" do
    get edit_todo_url(@todo)
    assert_response :success
  end

  test "should update todo" do
    patch todo_url(@todo), params: { todo: { 
      title: "Updated Title",
      description: @todo.description,
      priority: @todo.priority,
      completed: @todo.completed
    } }
    assert_redirected_to todos_url
  end

  test "should destroy todo" do
    assert_difference("Todo.count", -1) do
      delete todo_url(@todo)
    end

    assert_redirected_to todos_url
  end

  test "should toggle todo completion" do
    assert_not @todo.completed?
    
    patch toggle_todo_url(@todo)
    
    @todo.reload
    assert @todo.completed?
    assert_redirected_to todos_url
  end

  test "should handle toggle with turbo stream" do
    patch toggle_todo_url(@todo), as: :turbo_stream
    assert_response :success
    assert_match "turbo-stream", @response.media_type
  end
end