import { Controller } from "@hotwired/stimulus";

// Ce qu'on laisse voir du bloc au-dessus de l'en-tête, pour qu'on comprenne
// qu'il y a de la page derrière et non un écran qui s'est réinitialisé.
const RESPIRATION = 8;

export default class extends Controller {
  static targets = ["panel", "btn"];
  // `recentrer` : à l'ouverture, amener le bloc en haut de l'écran. Sur un
  // téléphone, ouvrir un domaine qui se trouve en bas fait apparaître ses
  // compétences SOUS le pli : on doit alors faire défiler soi-même avant de
  // pouvoir évaluer quoi que ce soit, alors qu'on vient précisément de désigner
  // ce qu'on voulait atteindre. C'est une valeur et non le comportement par
  // défaut : la liste des collègues d'une conversation se déplie sans que la
  // page ait à bouger.
  //
  // `entete` : le sélecteur de ce qui reste au-dessus du contenu et le
  // recouvrirait — l'en-tête collant de l'écran d'évaluation. Sa hauteur se
  // mesure, elle ne se devine pas : elle dépend de la marge d'encoche.
  static values = { recentrer: Boolean, entete: String };

  displayPanel() {
    // `toggle` rend l'état d'APRÈS : `false` veut dire que `d-none` vient d'être
    // retiré, donc que le panneau s'ouvre.
    const ouvert = this.panelTarget.classList.toggle("d-none") === false;
    // `btnTargets` et non `btnTarget` : l'écran d'évaluation en déclare deux —
    // le chevron fermé et le chevron ouvert — là où la conversation n'en
    // déclare qu'un. Et `btnTarget` seul levait sur les panneaux qui n'en
    // avaient aucun, ce qui était le cas des domaines du mobile.
    this.btnTargets.forEach((btn) => btn.classList.toggle("d-none"));

    if (ouvert && this.recentrerValue) this.#amener();
  }

  #amener() {
    const marge = this.#hauteurEntete() + RESPIRATION;
    const haut = this.element.getBoundingClientRect().top;
    const bas = this.panelTarget.getBoundingClientRect().bottom;

    // Rien à faire quand le domaine n'est ni recouvert par l'en-tête ni suivi de
    // compétences hors de l'écran : faire glisser la page sans nécessité coûte
    // plus en repères qu'elle ne rapporte.
    if (haut >= marge && bas <= window.innerHeight) return;

    window.scrollTo({
      top: Math.max(0, window.scrollY + haut - marge),
      behavior: this.#glissement()
    });
  }

  #hauteurEntete() {
    if (!this.hasEnteteValue) return 0;
    const entete = document.querySelector(this.enteteValue);
    return entete ? entete.getBoundingClientRect().height : 0;
  }

  // Un défilement animé est un mouvement de plus à l'écran : on le rend
  // instantané pour qui a demandé qu'on lui en épargne.
  #glissement() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth";
  }
}
