import { Controller } from "@hotwired/stimulus";

// Ajouter un domaine à un plan de travail, en deux temps : le domaine, puis sa
// ceinture. Un domaine spécial n'a qu'une ceinture : la blanche est cochée
// d'office, et l'étape 2 reste repliée. Les envois n'apparaissent qu'une fois
// la ceinture choisie.
//
// Le domaine spécial était reconnu à son libellé (« Géométrie », « Grandeurs
// et Mesures ») ; il l'est désormais par `data-special`, posé d'après le domaine.
export default class extends Controller {
  static targets = ["beltForm", "box", "btn"];

  displayBelt(event) {
    if (event.target.dataset.special === "true") {
      this.beltFormTarget.classList.add("d-none");
      this.boxTargets[0].checked = true;
      this.displayBtn();
    } else {
      this.beltFormTarget.classList.remove("d-none");
      if (!this.boxTargets.some((box) => box.checked)) this.#hideBtn();
    }
    window.scrollTo(0, document.body.scrollHeight);
  }

  displayBtn() {
    this.btnTargets.forEach((btn) => btn.classList.remove("d-none"));
  }

  #hideBtn() {
    this.btnTargets.forEach((btn) => btn.classList.add("d-none"));
  }
}
