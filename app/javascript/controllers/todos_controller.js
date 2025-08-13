import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-hide flash messages after 5 seconds
    const alerts = document.querySelectorAll('[data-turbo-temporary]')
    alerts.forEach(alert => {
      setTimeout(() => {
        alert.style.transition = 'opacity 0.5s'
        alert.style.opacity = '0'
        setTimeout(() => alert.remove(), 500)
      }, 5000)
    })
  }

  // Add smooth transitions when todos are updated
  toggleComplete(event) {
    const todoItem = event.currentTarget.closest('.todo-item')
    todoItem.style.transition = 'all 0.3s ease'
  }
}