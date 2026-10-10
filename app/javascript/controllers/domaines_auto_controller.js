import { Controller } from "@hotwired/stimulus"

// Modale « Nouveau plan de travail » : le premier clic sur « Auto, selon son
// niveau » n'envoie rien, il déplie les domaines à générer — cochés selon les
// préférences du professeur. Le second clic génère le plan.
//
// La liste est un `fieldset` désactivé tant qu'elle est repliée : un plan
// vierge n'envoie donc aucun domaine.
export default class extends Controller {
  static targets = ["domaines"]

  deplier(event) {
    if (!this.domainesTarget.hidden) return

    event.preventDefault()
    this.domainesTarget.hidden = false
    this.domainesTarget.disabled = false
    event.currentTarget.textContent = "Générer le plan"
  }
}
