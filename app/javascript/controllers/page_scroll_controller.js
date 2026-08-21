import { Controller } from "@hotwired/stimulus";

// Deux flèches flottantes pour aller d'un bout à l'autre d'une page longue.
//
// Le contrôleur `navigation` rend le même service sur la page d'un plan de travail,
// mais il va chercher ses boutons par `id` dans tout le document et son seuil
// d'affichage est une constante en pixels : on reste ici dans l'élément et on
// compare à la hauteur réelle de la fenêtre.
export default class extends Controller {
  static targets = ["up", "down"];
  // En dessous de ce reste à parcourir, la flèche n'a plus rien à offrir.
  static values = { margin: { type: Number, default: 100 } };

  connect() {
    // Déplier un dossier de compétence change la hauteur de la page sans qu'on
    // scrolle : sans cet observateur, la flèche du bas resterait cachée.
    this.observer = new ResizeObserver(() => this.refresh());
    this.observer.observe(document.body);
    this.refresh();
  }

  disconnect() {
    this.observer.disconnect();
  }

  refresh() {
    const scrolled = window.scrollY;
    const remaining = document.documentElement.scrollHeight - window.innerHeight - scrolled;
    this.#toggle(this.upTarget, scrolled > this.marginValue);
    this.#toggle(this.downTarget, remaining > this.marginValue);
  }

  up() {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  down() {
    window.scrollTo({ top: document.documentElement.scrollHeight, behavior: "smooth" });
  }

  #toggle(button, visible) {
    button.style.display = visible ? "block" : "none";
  }
}
