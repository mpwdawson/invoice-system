import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content"]

  reveal() {
    this.triggerTarget.hidden = true
    this.contentTarget.hidden = false
  }

  conceal() {
    this.contentTarget.hidden = true
    this.triggerTarget.hidden = false
  }
}
