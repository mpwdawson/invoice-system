import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hours", "date"]
  static values  = { url: String }

  connect() {
    this.savedHours = this.hoursTarget.value
    this.savedDate  = this.dateTarget.value
  }

  save() {
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        time_entry: {
          hours: this.hoursTarget.value,
          date:  this.dateTarget.value
        }
      })
    }).then(response => {
      if (response.ok) {
        this.savedHours = this.hoursTarget.value
        this.savedDate  = this.dateTarget.value
      } else {
        this.hoursTarget.value = this.savedHours
        this.dateTarget.value  = this.savedDate
      }
    })
  }
}
