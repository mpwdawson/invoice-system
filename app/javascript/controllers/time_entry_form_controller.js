import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "dateInput", "taskInput", "taskIdInput",
    "hoursInput", "previewFrame", "dropdownFrame",
    "autoSelectSlot"
  ]

  searchTask() {
    clearTimeout(this.#searchTimeout)
    this.#searchTimeout = setTimeout(() => {
      const q = this.taskInputTarget.value.trim()

      if (q.length < 1) {
        this.dropdownFrameTarget.innerHTML = ""
        return
      }
      this.dropdownFrameTarget.src = `/tasks/search?query=${encodeURIComponent(q)}`
    }, 150)
  }

  selectTask(event) {
    event.preventDefault()
    const el = event.currentTarget
    this.taskIdInputTarget.value = el.dataset.taskId
    this.taskInputTarget.value   = el.dataset.taskTitle
    this.dropdownFrameTarget.innerHTML = ""
    this.updatePreview()
  }

  autoSelectSlotTargetConnected(el) {
    this.taskIdInputTarget.value = el.dataset.taskId
    this.taskInputTarget.value   = el.dataset.taskTitle
    el.remove()
    this.updatePreview()
  }

  updatePreview() {
    const taskId = this.taskIdInputTarget.value
    const date   = this.dateInputTarget.value
    const hours  = this.hoursInputTarget.value
    if (!taskId || !date || !hours) return
    const params = new URLSearchParams({ task_id: taskId, date, hours })
    this.previewFrameTarget.src = `/time_entries/preview?${params}`
  }

  #searchTimeout = null
}
