class CreateTodos < ActiveRecord::Migration[8.0]
  def change
    create_table :todos do |t|
      t.string :title, null: false
      t.text :description
      t.boolean :completed, default: false, null: false
      t.integer :priority, default: 0
      t.datetime :due_date

      t.timestamps
    end

    add_index :todos, :completed
    add_index :todos, :due_date
  end
end
