import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]

  connect() {
    // Close dropdown when clicking outside
    document.addEventListener('click', this.closeDropdown.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.closeDropdown.bind(this))
  }

  toggle(event) {
    event.stopPropagation()
    this.dropdownTarget.classList.toggle('hidden')
  }

  selectLanguage(event) {
    const locale = event.currentTarget.dataset.locale
    
    // Create form and submit to change locale
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/set_locale'
    
    // Add CSRF token
    const csrfToken = document.querySelector('[name="csrf-token"]').getAttribute('content')
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    
    // Add locale parameter
    const localeInput = document.createElement('input')
    localeInput.type = 'hidden'
    localeInput.name = 'locale'
    localeInput.value = locale
    
    form.appendChild(csrfInput)
    form.appendChild(localeInput)
    document.body.appendChild(form)
    form.submit()
  }

  closeDropdown(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add('hidden')
    }
  }
}