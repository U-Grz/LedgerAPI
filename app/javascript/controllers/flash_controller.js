import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    // Auto-dismiss after 5 seconds
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, 5000)
  }

  dismiss() {
    // Clear the timeout and remove the element
    clearTimeout(this.timeout)
    this.element.remove()
  }

  disconnect() {
    // Clean up timeout when controller is disconnected
    clearTimeout(this.timeout)
  }
}