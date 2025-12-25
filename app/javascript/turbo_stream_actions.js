import { StreamActions } from "@hotwired/turbo"

StreamActions.remove_with_animation = function() {
  const targetElement = this.targetElements[0]
  
  if (targetElement) {
    targetElement.classList.add('animate-slide-out')
    
    setTimeout(() => {
      targetElement.remove()
    }, 300)
  }
}
