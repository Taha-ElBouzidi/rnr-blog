import { Controller } from "@hotwired/stimulus"

// Auto-submit filter form when inputs change
export default class extends Controller {
  static targets = ["search"]

  submit() {
    // Clear any existing timeout to debounce rapid changes
    clearTimeout(this.timeout)
    
    // Submit after a short delay
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300)
  }

  clear(event) {
    event.preventDefault()
    
    // Navigate to posts path with current status only (clears search and author filters)
    const form = this.element
    const statusInput = form.querySelector('input[name="status"]')
    const statusValue = statusInput ? statusInput.value : ''
    
    // Build URL with only status param if present
    const url = statusValue ? `/posts?status=${statusValue}` : '/posts'
    
    // Use Turbo to navigate
    window.Turbo.visit(url)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
