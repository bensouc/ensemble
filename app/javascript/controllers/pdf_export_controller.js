import { Controller } from "@hotwired/stimulus"
import { hasUnsavedChanges, isBusy, onChange } from "../plugins/save_tracker"

// Garde de l'export PDF.
//
// L'attente, elle, est affichée par la page `work_plans#export` ouverte dans
// l'onglet : au clic, le regard part dans le nouvel onglet, un indicateur posé ici
// ne servirait personne.

export default class extends Controller {
  connect() {
    this.setBusy = this.setBusy.bind(this)
    this.unsubscribe = onChange(this.setBusy)
    this.setBusy(isBusy())
  }

  disconnect() {
    this.unsubscribe?.()
  }

  guard(event) {
    // Filet : `pointer-events: none` empêche déjà le clic, mais le lien reste
    // atteignable au clavier.
    if (isBusy()) {
      event.preventDefault()
      return
    }

    // Du non enregistré ne se résout pas en attendant : on prévient, et on laisse
    // décider. Confirmation synchrone, donc la navigation du lien continue
    // normalement si elle est acceptée.
    if (hasUnsavedChanges()) {
      const proceed = window.confirm(
        "Des modifications ne sont pas enregistrées.\nLe PDF ne les contiendra pas.\n\nExporter quand même ?"
      )
      if (!proceed) event.preventDefault()
    }
  }

  // --- Indisponibilité pendant un enregistrement ----------------------------

  setBusy(busy) {
    this.element.classList.toggle("is-saving", busy)
    this.element.setAttribute("aria-disabled", busy ? "true" : "false")
    if (busy) {
      this.element.dataset.savingTitle ||= this.element.getAttribute("title") || ""
      this.element.setAttribute("title", "Enregistrement en cours…")
    } else if ("savingTitle" in this.element.dataset) {
      this.element.setAttribute("title", this.element.dataset.savingTitle)
    }
  }
}
