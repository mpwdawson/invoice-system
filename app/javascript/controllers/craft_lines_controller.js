import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggleRow(event) {
    const row = event.currentTarget.closest("tr")
    const nameInput = row.querySelector('input[type="text"]')
    const checked = event.currentTarget.checked

    nameInput.disabled = !checked
    nameInput.classList.toggle("opacity-50", !checked)

    if (checked && !nameInput.value) {
      nameInput.value = nameInput.placeholder
    }
  }
}
