import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Initialize theme from session storage or default to light
    const savedTheme = sessionStorage.getItem('theme') || 'light'
    this.setTheme(savedTheme)
  }

  toggle() {
    const currentTheme = document.documentElement.getAttribute('data-theme') || 'light'
    const newTheme = currentTheme === 'light' ? 'dark' : 'light'
    this.setTheme(newTheme)
  }

  setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme)
    sessionStorage.setItem('theme', theme)
    
    // Update button hover animation
    const button = this.element
    button.style.transform = 'scale(0.95)'
    setTimeout(() => {
      button.style.transform = ''
    }, 150)
  }
}