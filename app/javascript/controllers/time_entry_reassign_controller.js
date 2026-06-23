import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop", "taskInput", "taskIdInput", "dropdownFrame", "form"]
  static values  = { customerId: String }

  open(event) {
    const entryId = event.currentTarget.dataset.timeEntryId
    this.formTarget.action = `/time_entries/${entryId}/reassign`
    this.taskInputTarget.value   = ""
    this.taskIdInputTarget.value = ""
    this.dropdownFrameTarget.innerHTML = ""
    this.modalTarget.classList.remove("hidden")
    this.backdropTarget.classList.remove("hidden")
    this.taskInputTarget.focus()
  }

  close() {
    this.modalTarget.classList.add("hidden")
    this.backdropTarget.classList.add("hidden")
  }

  searchTask() {
    clearTimeout(this._searchTimeout)
    this._searchTimeout = setTimeout(() => {
      const q = this.taskInputTarget.value.trim()
      if (q.length < 1) {
        this.dropdownFrameTarget.innerHTML = ""
        return
      }
      const params = new URLSearchParams({ query: q })
      if (this.customerIdValue) params.set("customer_id", this.customerIdValue)
      this.dropdownFrameTarget.src = `/tasks/search?${params}`
    }, 150)
  }

  selectTask(event) {
    const el = event.target.closest("[data-task-id]")
    if (!el) return
    event.preventDefault()
    this.taskIdInputTarget.value = el.dataset.taskId
    this.taskInputTarget.value   = el.dataset.taskTitle
    this.dropdownFrameTarget.innerHTML = ""
  }

  _searchTimeout = null
}
