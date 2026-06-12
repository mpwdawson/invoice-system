import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "resultsFrame"]
  static values  = { searchUrl: String }

  search() {
    clearTimeout(this.#timeout)
    this.#timeout = setTimeout(() => this.#updateFrame(), 300)
  }

  #updateFrame() {
    const q = this.queryTarget.value.trim()

    if (q.length < 2) {
      this.resultsFrameTarget.innerHTML = ""
      return
    }
    const url = new URL(this.searchUrlValue, window.location.origin)

    url.searchParams.set("q", q)
    this.resultsFrameTarget.src = url.toString()
  }

  #timeout = null
}
