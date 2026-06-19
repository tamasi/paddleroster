import { Controller } from "@hotwired/stimulus"

const POLL_INTERVAL_MS = 3000

export default class extends Controller {
  connect() {
    if (this.element.dataset.status === "connecting") {
      // No usamos frame.reload() / src declarativo a propósito: el partial que
      // responde este fetch es el mismo que arma este frame, así que si tuviera
      // `src` Turbo lo detecta como "fuente que se referencia a sí misma" y se
      // niega a reemplazar el contenido (frame queda vacío, ver Story 1.7 fix).
      // Reasignar `.src` desde JS en cada tick sí dispara el fetch sin ese problema.
      this.interval = setInterval(() => {
        this.element.src = this.element.dataset.pollUrl
      }, POLL_INTERVAL_MS)
    }
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }
}
