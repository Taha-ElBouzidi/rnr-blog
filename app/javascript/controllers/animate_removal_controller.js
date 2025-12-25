import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  remove() {
    this.element.classList.add('animate-slide-out')
    
    // Wait for animation to complete before removing element
    setTimeout(() => {
      this.element.remove()
    }, 300) // Match the animation duration
  }
}
