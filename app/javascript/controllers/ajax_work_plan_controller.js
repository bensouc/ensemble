import { Controller } from "@hotwired/stimulus";
import { Tooltip } from "bootstrap";
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

    this.peindre(statut, lien.dataset.libelle);
    this.marquerChoix(lien);
    this.marquerEnAttente(true);
    this.masquerInfobulles(lien);
    file.ajouter({ id, url, statut });
  }

  // Les infobulles du contrôle restaient à l'écran une fois le statut choisi,
  // et s'y empilaient d'une compétence à l'autre.
  //
  // Bootstrap déclenche une infobulle au survol ET au focus. Un `<a>` cliqué
  // garde le focus, donc la sienne n'avait aucune raison de partir : sortir la
  // souris ne suffisait pas, seul un clic ailleurs l'aurait fait. On la ferme
  // donc à la main, et on rend le focus — sans quoi elle reparaîtrait aussitôt.
  //
  // Toutes celles de la ligne, et pas seulement celle du lien cliqué : deux
  // cases voisines font 43px de large, on passe de l'une à l'autre plus vite
  // que le délai de fermeture, et il en restait une ouverte derrière soi.
  masquerInfobulles(lien) {
    lien.blur();
    this.element
      .querySelectorAll('[data-bs-toggle="tooltip"]')
      .forEach((cible) => Tooltip.getInstance(cible)?.hide());
  }

  // --- rendu ------------------------------------------------------------

  // Peinture optimiste de la pastille isolée du mobile : elle prend le nouveau
  // statut sans attendre le réseau. `not_done` ramène la compétence à l'état
  // neuf — c'est la seule correspondance que le serveur ne recopie pas telle
  // quelle.
  //
  // Les deux rappels sont visés nommément plutôt que par un `querySelector` sur
  // `lastEvalTarget` : les cinq cases du contrôle sont elles aussi des
  // pastilles, et la première serait repeinte à tort.
  peindre(statut, libelle) {
    const pastille = this.element.querySelector(".eval-courant .eval_bull, .mobile-last-eval .eval_bull");
    if (!pastille) return;

    const attendu = statut === "not_done" ? "new" : statut;
    pastille.className = `eval_bull ${attendu}`;
    if (libelle) this.reetiqueter(pastille, libelle);
  }

  // Une infobulle Bootstrap retient le texte qu'elle avait à sa construction :
  // changer l'attribut `title` ne suffit pas, il faut le lui dire. Sans quoi la
  // pastille annoncerait encore le statut d'avant jusqu'à la réponse du
  // serveur — et, hors ligne, jusqu'à la synchronisation.
  //
  // Le mot vient de la case cliquée, qui le porte déjà : le recopier en
  // JavaScript le ferait diverger de la table des libellés.
  reetiqueter(pastille, libelle) {
    pastille.setAttribute("title", libelle);
    Tooltip.getInstance(pastille)?.setContent({ ".tooltip-inner": libelle });
  }

  // Déplace la marque du statut courant. Au bureau c'est la peinture optimiste
  // elle-même : le contrôle EST l'affichage de l'état, une case encadrée parmi
  // cinq. Au mobile, c'est la modale qui se tient à jour — rendue une seule
  // fois au chargement, elle montrerait sinon un choix périmé à la réouverture.
  marquerChoix(lien) {
    const choix = this.element.querySelectorAll(".eval-case, .mobile-eval-choix");
    if (choix.length === 0) return;

    choix.forEach((autre) => {
      autre.classList.remove("--courant");
      autre.removeAttribute("aria-current");
    });
    const choisi = lien.closest(".eval-case, .mobile-eval-choix");
    if (!choisi) return;

    choisi.classList.add("--courant");
    choisi.setAttribute("aria-current", "true");
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
