import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this)
  }

  disconnect() {
    this.removeEventListeners()
  }

  toggle() {
    if (this.dropdownTarget.classList.contains("show")) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.dropdownTarget.classList.add("show")
    document.addEventListener("click", this.boundClickOutside)
  }

  close() {
    this.dropdownTarget.classList.remove("show")
    this.removeEventListeners()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  removeEventListeners() {
    document.removeEventListener("click", this.boundClickOutside)
  }
}