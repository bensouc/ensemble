import { Controller } from "@hotwired/stimulus"

// Les filtres de « Les problèmes » se resserrent les uns les autres : le
// niveau choisi limite les domaines, et les deux limitent les compétences.
// C'est le serveur qui connaît ces listes — mille compétences ne voyagent pas
// jusqu'au navigateur — donc la page repart à chaque changement, plutôt que
// d'attendre un bouton qu'on oublie de cliquer.
export default class extends Controller {
  static targets = ["domaine"]

  envoyer(event) {
    // Changer de niveau périme le domaine déjà choisi : il appartient
    // peut-être à un autre niveau, et le couple ne désignerait alors aucune
    // compétence. On le vide avant de partir.
    if (event.target.name === "niveau" && this.hasDomaineTarget) {
      this.domaineTarget.value = ""
    }
    this.element.requestSubmit()
  }
}
