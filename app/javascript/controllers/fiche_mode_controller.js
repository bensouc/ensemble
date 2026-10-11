import { Controller } from "@hotwired/stimulus"

// La modale d'une nouvelle fiche de ceinture : changer de façon de préparer
// montre ce que celle-ci met dans chaque domaine, et coche d'avance ceux où elle
// met quelque chose. Le rendu serveur porte déjà le mode d'entrée.
export default class extends Controller {
  static targets = ["domaine"]
  static values = { mode: String }

  choisir(event) {
    this.modeValue = event.target.value
    this.domaineTargets.forEach((domaine) => {
      const cle = this.modeValue === "en_cours" ? "enCours" : "resultats"
      domaine.querySelector("input[type=checkbox]").checked = domaine.dataset[cle] === "true"
    })
  }

  modeValueChanged() {
    this.element.dataset.mode = this.modeValue
  }
}
