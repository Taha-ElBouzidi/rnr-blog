import { Controller } from "@hotwired/stimulus"

// Disables submit button and shows "Saving..." text
export default class extends Controller {
  static targets = ["submit"]

  disableSubmit(event) {
    const submitButton = this.submitTarget
    
    // Store original text
    submitButton.dataset.originalText = submitButton.textContent
    
    // Disable button and change text
    submitButton.disabled = true
    submitButton.textContent = "Saving..."
    submitButton.classList.add("opacity-50", "cursor-not-allowed")
  }

  // Re-enable on form errors (Turbo intercepts success)
  enable() {
    const submitButton = this.submitTarget
    
    submitButton.disabled = false
    submitButton.textContent = submitButton.dataset.originalText || "Submit"
    submitButton.classList.remove("opacity-50", "cursor-not-allowed")
  }
}
