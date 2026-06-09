import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  static values  = { url: String, model: String, field: String }

  connect() {
    this.saved = this.inputTarget.value
  }

  schedule() {
    clearTimeout(this.timer)
    const current = this.inputTarget.value.trim()
    if (!current || current === this.saved) return
    this.timer = setTimeout(() => this.persist(), 600)
  }

  cancel() {
    clearTimeout(this.timer)
    this.inputTarget.value = this.saved
    this.inputTarget.blur()
  }

  persist() {
    const value = this.inputTarget.value.trim()
    if (!value) { this.cancel(); return }

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ [this.modelValue]: { [this.fieldValue]: value } })
    }).then(response => {
      if (response.ok) {
        this.saved = value
      } else {
        this.inputTarget.value = this.saved
      }
    })
  }
}
