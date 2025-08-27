class TodosController < ApplicationController
  before_action :set_todo, only: [ :edit, :update, :destroy, :toggle ]

  def index
    @todos = Todo.ordered
    @overdue_todos = Todo.overdue.ordered
  end

  def new
    @todo = Todo.new
  end

  def create
    @todo = Todo.new(todo_params)

    if @todo.save
      redirect_to todos_path, notice: t("flash.todo_created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @todo.update(todo_params)
      redirect_to todos_path, notice: t("flash.todo_updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @todo.destroy
    redirect_to todos_path, notice: t("flash.todo_deleted"), status: :see_other
  end

  def toggle
    @todo.toggle_completed!

    respond_to do |format|
      format.html { redirect_to todos_path }
      format.turbo_stream
    end
  end

  private

  def set_todo
    @todo = Todo.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :description, :priority, :due_date, :completed)
  end
end
