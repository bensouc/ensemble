import { Controller } from "@hotwired/stimulus"
import { hasUnsavedChanges, isBusy, onChange } from "../plugins/save_tracker"

// Rend l'export PDF indisponible tant qu'un enregistrement est en vol.
//
// Le PDF est rendu côté serveur à partir de la base : demandé pendant qu'une
// sauvegarde est en route, il sort sur l'état précédent — sans erreur, donc sans
// que rien ne le signale. Plutôt qu'un délai arbitraire, on suit l'état réel des
// enregistrements (cf. `plugins/save_tracker`), qui dure typiquement une centaine
// de millisecondes.
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
    if (!hasUnsavedChanges()) return

    const proceed = window.confirm(
      "Des modifications ne sont pas enregistrées.\nLe PDF ne les contiendra pas.\n\nExporter quand même ?"
    )
    if (!proceed) event.preventDefault()
  }

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
