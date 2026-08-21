import { Controller } from "@hotwired/stimulus"

// Amène un élément dans la vue dès son apparition, et le signale brièvement.
//
// Utilisé après un clonage : la copie atterrit en dernière position de la compétence,
// donc hors écran dès qu'elle en compte quelques-uns — l'enseignant cliquait sans
// rien voir se passer.
const HIGHLIGHT_DURATION = 1800

export default class extends Controller {
  connect() {
    this.element.scrollIntoView({ behavior: "smooth", block: "center" })
    this.element.classList.add("is-revealed")
    this.timer = setTimeout(() => this.element.classList.remove("is-revealed"), HIGHLIGHT_DURATION)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
