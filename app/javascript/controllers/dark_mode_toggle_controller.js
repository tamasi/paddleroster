import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const isDark = document.documentElement.classList.toggle("dark")
    try {
      localStorage.theme = isDark ? "dark" : "light"
    } catch (e) {
      // Fallback for restricted storage access
    }
  }
}
