import { Controller } from "@hotwired/stimulus";
import { file } from "../eval_queue";

// Un appui sur un statut d'évaluation.
//
// Avant, le clic partait en `fetch` et, en cas d'échec, se soldait par un
// `console.log("Raté l eval")` : l'écran ne bougeait pas et l'enseignant n'avait
// aucun moyen de savoir que sa validation était perdue. Le geste est désormais
// peint tout de suite, confié à la file, et marqué « en attente » tant que le
// serveur ne l'a pas confirmé.
export default class extends Controller {
  static targets = ["lastEval"];
  static values = { id: Number };

  connect() {
    this.surEnregistrement = (event) => this.confirmer(event.detail);
    document.addEventListener("eval-queue:enregistre", this.surEnregistrement);
    // Un retour sur la page — navigation Turbo, PWA rouverte — ne doit pas
    // effacer la marque d'un geste encore en file.
    if (this.enFile()) this.marquerEnAttente(true);
  }

  disconnect() {
    document.removeEventListener("eval-queue:enregistre", this.surEnregistrement);
  }

  toggle(event) {
    event.preventDefault();
    event.stopImmediatePropagation();

    const lien = event.target.closest("a");
    const url = lien?.href;
    if (!url || url.includes("undefined") || url.includes("null")) return;

    const id = this.idDepuis(url);
    const statut = new URL(url, window.location.origin).searchParams.get("status");
    if (!id || !statut) return;

    this.peindre(statut);
    this.marquerEnAttente(true);
    file.ajouter({ id, url, statut });
  }

  // --- rendu ------------------------------------------------------------

  // Peinture optimiste : la pastille prend le nouveau statut sans attendre le
  // réseau. `not_done` ramène la compétence à l'état neuf — c'est la seule
  // correspondance que le serveur ne recopie pas telle quelle.
  peindre(statut) {
    if (!this.hasLastEvalTarget) return;

    const pastille = this.lastEvalTarget.querySelector(".eval_bull");
    if (!pastille) return;

    const attendu = statut === "not_done" ? "new" : statut;
    pastille.className = `eval_bull ${attendu}`;
  }

  // Le serveur a le dernier mot : sa réponse remplace la pastille peinte.
  confirmer({ id, html }) {
    if (id !== this.idValue) return;

    if (this.hasLastEvalTarget && html) this.lastEvalTarget.innerHTML = html;
    this.marquerEnAttente(false);
  }

  marquerEnAttente(enAttente) {
    this.element.classList.toggle("eval-en-attente", enAttente);
  }

  // --- utilitaires ------------------------------------------------------

  enFile() {
    return file.entrees.some((entree) => entree.id === this.idValue);
  }

  idDepuis(url) {
    const trouve = url.match(/work_plan_skills\/(\d+)\/eval_update/);
    return trouve ? Number(trouve[1]) : null;
  }
}
