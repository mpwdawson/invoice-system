import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "form"]

  start(event) {
    this.dragged = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
  }

  over(event) {
    event.preventDefault()
    const target = event.currentTarget
    if (target === this.dragged) return

    const items = this.itemTargets
    if (items.indexOf(this.dragged) < items.indexOf(target)) {
      target.after(this.dragged)
    } else {
      target.before(this.dragged)
    }
  }

  end() {
    const form = this.formTarget
    form.querySelectorAll('input[name="line_ids[]"]').forEach(el => el.remove())
    this.itemTargets.forEach(item => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'line_ids[]'
      input.value = item.dataset.lineId
      form.appendChild(input)
    })
    form.requestSubmit()
  }
}
