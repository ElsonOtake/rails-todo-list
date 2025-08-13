require "application_system_test_case"

class TodosTest < ApplicationSystemTestCase
  setup do
    @todo = todos(:one)
  end

  test "visiting the index" do
    visit todos_url
    assert_selector "h1", text: "My Todos"
  end

  test "should create todo" do
    visit todos_url
    click_on "New Todo"

    fill_in "Title", with: "System test todo"
    fill_in "Description", with: "This is a test description"
    select "Medium Priority", from: "Priority"

    click_on "Create Todo"

    assert_text "Todo was successfully created"
    assert_text "System test todo"
  end

  test "should update todo" do
    visit todos_url

    within "#todo_#{@todo.id}" do
      find(".action-btn[title='Edit']").click
    end

    fill_in "Title", with: "Updated todo title"
    click_on "Update Todo"

    assert_text "Todo was successfully updated"
    assert_text "Updated todo title"
  end

  test "should destroy todo" do
    visit todos_url

    assert_text @todo.title

    within "#todo_#{@todo.id}" do
      accept_confirm do
        find(".action-btn-danger[title='Delete']").click
      end
    end

    assert_text "Todo was successfully deleted"
    assert_no_text @todo.title
  end

  test "should toggle todo completion" do
    visit todos_url

    within "#todo_#{@todo.id}" do
      assert_no_selector ".completed"
      find(".checkbox-btn").click
    end

    within "#todo_#{@todo.id}" do
      assert_selector ".completed"
    end
  end

  test "should show empty state when no todos" do
    Todo.destroy_all
    visit todos_url

    assert_selector ".empty-state"
    assert_text "No todos yet"
    assert_text "Create your first todo to get started"
  end

  test "should show overdue warning" do
    Todo.create!(
      title: "Overdue task",
      completed: false,
      due_date: 2.days.ago
    )

    visit todos_url

    assert_selector ".alert-warning"
    assert_text "overdue task"
  end

  test "should display priority badges" do
    Todo.create!(title: "High priority", priority: "high")
    Todo.create!(title: "Medium priority", priority: "medium")
    Todo.create!(title: "Low priority", priority: "low")

    visit todos_url

    assert_selector ".badge-high", text: "HIGH"
    assert_selector ".badge-medium", text: "MEDIUM"
    assert_selector ".badge-low", text: "LOW"
  end

  test "should validate todo creation" do
    visit todos_url
    click_on "New Todo"

    # Try to submit without title
    click_on "Create Todo"

    assert_text "Please fix the following errors"
    assert_text "Title can't be blank"
  end
end
