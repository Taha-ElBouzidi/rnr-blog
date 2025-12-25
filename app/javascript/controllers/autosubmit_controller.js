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
    
    // Clear the search input
    if (this.hasSearchTarget) {
      this.searchTarget.value = ""
    }
    
    // Clear all select dropdowns by resetting form
    this.element.reset()
    
    // Submit to show all posts
    this.element.requestSubmit()
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
