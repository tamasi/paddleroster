import { Controller } from "@hotwired/stimulus"

const THRESHOLD = 80

export default class extends Controller {
  connect() {
    this.startY = null
    this.onTouchStart = this.touchStart.bind(this)
    this.onTouchMove = this.touchMove.bind(this)
    this.onTouchEnd = this.touchEnd.bind(this)

    this.element.addEventListener("touchstart", this.onTouchStart, { passive: true })
    this.element.addEventListener("touchmove", this.onTouchMove, { passive: true })
    this.element.addEventListener("touchend", this.onTouchEnd)
  }

  disconnect() {
    this.element.removeEventListener("touchstart", this.onTouchStart)
    this.element.removeEventListener("touchmove", this.onTouchMove)
    this.element.removeEventListener("touchend", this.onTouchEnd)
  }

  touchStart(event) {
    if (window.scrollY > 0) {
      this.startY = null
      return
    }

    this.startY = event.touches[0].clientY
    this.pulled = 0
  }

  touchMove(event) {
    if (this.startY === null) return

    this.pulled = event.touches[0].clientY - this.startY
  }

  touchEnd() {
    if (this.pulled > THRESHOLD) {
      Turbo.visit(window.location.href, { action: "replace" })
    }

    this.startY = null
    this.pulled = 0
  }
}
