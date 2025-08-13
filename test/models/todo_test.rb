require "test_helper"

class TodoTest < ActiveSupport::TestCase
  def setup
    @todo = Todo.new(
      title: "Test Todo",
      description: "Test description",
      priority: "low",
      completed: false,
      due_date: 1.day.from_now
    )
  end

  test "should be valid with valid attributes" do
    assert @todo.valid?
  end

  test "should require a title" do
    @todo.title = nil
    assert_not @todo.valid?
    assert_includes @todo.errors[:title], "can't be blank"
  end

  test "should have default completed value of false" do
    todo = Todo.new(title: "New Todo")
    assert_equal false, todo.completed
  end

  test "should have default priority value of low" do
    todo = Todo.new(title: "New Todo")
    assert_equal "low", todo.priority
  end

  test "should toggle completed status" do
    @todo.save
    assert_not @todo.completed?

    @todo.toggle_completed!
    assert @todo.completed?

    @todo.toggle_completed!
    assert_not @todo.completed?
  end

  test "should identify overdue todos" do
    @todo.due_date = 1.day.ago
    @todo.completed = false
    assert @todo.overdue?
  end

  test "should not be overdue if completed" do
    @todo.due_date = 1.day.ago
    @todo.completed = true
    assert_not @todo.overdue?
  end

  test "should not be overdue if no due date" do
    @todo.due_date = nil
    assert_not @todo.overdue?
  end

  test "should not be overdue if due date is in future" do
    @todo.due_date = 1.day.from_now
    assert_not @todo.overdue?
  end

  test "incomplete scope should return only incomplete todos" do
    todo1 = Todo.create!(title: "Incomplete", completed: false)
    todo2 = Todo.create!(title: "Complete", completed: true)

    incomplete_todos = Todo.incomplete
    assert_includes incomplete_todos, todo1
    assert_not_includes incomplete_todos, todo2
  end

  test "complete scope should return only completed todos" do
    todo1 = Todo.create!(title: "Incomplete", completed: false)
    todo2 = Todo.create!(title: "Complete", completed: true)

    complete_todos = Todo.complete
    assert_not_includes complete_todos, todo1
    assert_includes complete_todos, todo2
  end

  test "overdue scope should return only overdue todos" do
    todo1 = Todo.create!(title: "Overdue", completed: false, due_date: 1.day.ago)
    todo2 = Todo.create!(title: "Not overdue", completed: false, due_date: 1.day.from_now)
    todo3 = Todo.create!(title: "Completed overdue", completed: true, due_date: 1.day.ago)

    overdue_todos = Todo.overdue
    assert_includes overdue_todos, todo1
    assert_not_includes overdue_todos, todo2
    assert_not_includes overdue_todos, todo3
  end

  test "ordered scope should order todos correctly" do
    todo1 = Todo.create!(title: "High priority incomplete", priority: "high", completed: false, due_date: 1.day.from_now)
    todo2 = Todo.create!(title: "Low priority incomplete", priority: "low", completed: false, due_date: 2.days.from_now)
    todo3 = Todo.create!(title: "Completed", priority: "high", completed: true)

    ordered_todos = Todo.ordered

    # Incomplete todos should come before completed ones
    assert ordered_todos.index(todo1) < ordered_todos.index(todo3)
    assert ordered_todos.index(todo2) < ordered_todos.index(todo3)

    # Among incomplete todos, higher priority should come first
    assert ordered_todos.index(todo1) < ordered_todos.index(todo2)
  end

  test "priority enum should work correctly" do
    @todo.priority = "low"
    assert @todo.low?

    @todo.priority = "medium"
    assert @todo.medium?

    @todo.priority = "high"
    assert @todo.high?
  end
end
