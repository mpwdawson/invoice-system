import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["expenseFields"]

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

  toggleExpense(event) {
    const fields = this.expenseFieldsTarget
    const inputs = fields.querySelectorAll("input")
    const checked = event.currentTarget.checked

    inputs.forEach(input => input.disabled = !checked)
    fields.classList.toggle("opacity-50", !checked)
  }
}
