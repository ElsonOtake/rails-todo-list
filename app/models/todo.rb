class Todo < ApplicationRecord
  validates :title, presence: true

  enum :priority, { low: 0, medium: 1, high: 2 }

  scope :incomplete, -> { where(completed: false) }
  scope :complete, -> { where(completed: true) }
  scope :overdue, -> { where("due_date < ? AND completed = ?", Time.current, false) }
  scope :ordered, -> { order(completed: :asc, priority: :desc, due_date: :asc, created_at: :desc) }

  def overdue?
    due_date.present? && due_date < Time.current && !completed?
  end

  def toggle_completed!
    update(completed: !completed)
  end
end
