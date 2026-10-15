import { Controller } from "@hotwired/stimulus"

// Une fenêtre plus haute que l'écran le dit, en bas, tant qu'il en reste à
// lire. Les boutons d'une annonce sont tout en bas : rien n'indiquait qu'il
// fallait faire défiler pour les atteindre, et l'annonce revenait sans fin.
export default class extends Controller {
  static targets = ["indice"]

  connect() {
    this.verifier = this.verifier.bind(this)
    this.element.addEventListener("scroll", this.verifier, { passive: true })
    window.addEventListener("resize", this.verifier)
    // Les captures arrivent après coup, et la hauteur avec elles.
    this.element.querySelectorAll("img").forEach((image) => image.addEventListener("load", this.verifier))
    this.verifier()
  }

  disconnect() {
    this.element.removeEventListener("scroll", this.verifier)
    window.removeEventListener("resize", this.verifier)
    this.element.querySelectorAll("img").forEach((image) => image.removeEventListener("load", this.verifier))
  }

  verifier() {
    const reste = this.element.scrollHeight - this.element.scrollTop - this.element.clientHeight
    this.indiceTarget.hidden = reste <= 8
  }

  descendre() {
    this.element.scrollTo({ top: this.element.scrollHeight, behavior: "smooth" })
  }
}
