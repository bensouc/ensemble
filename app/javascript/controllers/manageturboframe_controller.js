import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // L'identifiant complet de la frame : celle d'un exercice de ceinture est
  // préfixée (`for_belt_skill_…`), on ne peut plus la reconstruire ici.
  static values = {
    frame: String
  }
  connect() {
    // console.log('managetruborgrame OK connected');

  }

  cleanTurboFrame() {
    const turboFrame = document.getElementById(this.frameValue)

    turboFrame.innerHTML = ""
  }

}
