import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "link", "editButton"]
  static values  = { url: String, model: String, field: String }

  connect() {
    this.saved = this.inputTarget.value
  }

  edit() {
    this.linkTarget.classList.add("hidden")
    this.editButtonTarget.classList.remove("group-hover:inline-flex")
    this.inputTarget.classList.remove("hidden")
    this.inputTarget.focus()
    const len = this.inputTarget.value.length
    this.inputTarget.setSelectionRange(len, len)
  }

  save(event) {
    event.preventDefault()
    this.inputTarget.blur()
  }

  cancel() {
    clearTimeout(this.timer)
    this.inputTarget.value = this.saved
    this.inputTarget.classList.add("hidden")
    this.linkTarget.classList.remove("hidden")
    this.editButtonTarget.classList.add("group-hover:inline-flex")
  }

  blur() {
    const current = this.inputTarget.value.trim()
    if (!current || current === this.saved) {
      this.cancel()
    } else {
      this.persist()
    }
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
        this.inputTarget.classList.add("hidden")
        this.linkTarget.classList.remove("hidden")
        this.editButtonTarget.classList.add("group-hover:inline-flex")
        document.querySelectorAll(`[data-tasks--inline-edit-url-value="${this.urlValue}"]`).forEach(el => {
          const link = el.querySelector('[data-tasks--inline-edit-target="link"]')
          const input = el.querySelector('[data-tasks--inline-edit-target="input"]')
          if (link) link.textContent = value
          if (input) input.value = value
        })
      } else {
        this.cancel()
      }
    })
  }
}
