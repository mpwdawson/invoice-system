import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  initialize() {
    this.applyTheme = this.applyTheme.bind(this)
  }

  connect() {
    this.applyTheme()
    document.addEventListener("turbo:load", this.applyTheme)
    document.addEventListener("turbo:morph", this.applyTheme)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.applyTheme)
    document.removeEventListener("turbo:morph", this.applyTheme)
  }

  toggle() {
    const isDark = document.documentElement.classList.toggle("dark")
    localStorage.setItem("theme", isDark ? "dark" : "light")
  }

  applyTheme() {
    document.documentElement.classList.toggle("dark", localStorage.getItem("theme") === "dark")
  }
}
