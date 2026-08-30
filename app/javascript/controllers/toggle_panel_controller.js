import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel", "btn"];

  displayPanel() {
    this.panelTarget.classList.toggle("d-none");
    // `btnTargets` et non `btnTarget` : l'écran d'évaluation en déclare deux —
    // le chevron fermé et le chevron ouvert — là où la conversation n'en
    // déclare qu'un. Et `btnTarget` seul levait sur les panneaux qui n'en
    // avaient aucun, ce qui était le cas des domaines du mobile.
    this.btnTargets.forEach((btn) => btn.classList.toggle("d-none"));
  }
}
