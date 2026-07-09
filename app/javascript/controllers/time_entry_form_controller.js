import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "dateInput", "taskInput", "taskIdInput",
    "hoursInput", "previewFrame", "dropdownFrame",
    "autoSelectSlot"
  ]

  static values = { customerId: String }

  connect() {
    this.#boundCheckDate = this.#checkDate.bind(this)
    document.addEventListener('visibilitychange', this.#boundCheckDate)
  }

  disconnect() {
    document.removeEventListener('visibilitychange', this.#boundCheckDate)
  }

  reset(event) {
    if (!event.detail.success) return
    this.clear()
  }

  clear() {
    this.taskInputTarget.value    = ""
    this.taskIdInputTarget.value  = ""
    this.hoursInputTarget.value   = ""
    this.dropdownFrameTarget.innerHTML = ""
    this.previewFrameTarget.removeAttribute("src")
    this.previewFrameTarget.innerHTML = ""
  }

  searchTask() {
    clearTimeout(this.#searchTimeout)
    this.#searchTimeout = setTimeout(() => {
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
    event.preventDefault()
    const el = event.currentTarget
    this.taskIdInputTarget.value = el.dataset.taskId
    this.taskInputTarget.value   = el.dataset.taskTitle
    this.dropdownFrameTarget.innerHTML = ""
    this.updatePreview()
  }

  setDate(event) {
    this.dateInputTarget.value = event.currentTarget.dataset.date
    this.dateInputTarget.scrollIntoView({ behavior: 'smooth', block: 'center' })
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
    if (!taskId || !date) return
    const params = new URLSearchParams({ task_id: taskId, date, hours })
    this.previewFrameTarget.src = `/time_entries/preview?${params}`
  }

  #searchTimeout  = null
  #boundCheckDate = null

  #checkDate() {
    if (document.visibilityState !== 'visible') return
    const today = new Date().toLocaleDateString('en-CA')

    if (this.dateInputTarget.value !== today) {
      this.dateInputTarget.value = today
    }
  }
}
