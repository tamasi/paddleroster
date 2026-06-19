import { Controller } from "@hotwired/stimulus"

const POLL_INTERVAL_MS = 3000

export default class extends Controller {
  connect() {
    if (this.element.dataset.status === "connecting") {
      this.interval = setInterval(() => this.element.reload(), POLL_INTERVAL_MS)
    }
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }
}
