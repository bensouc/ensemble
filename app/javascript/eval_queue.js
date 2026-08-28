// File d'attente des évaluations du front mobile.
//
// Un appui sur un statut est d'abord ÉCRIT localement, puis envoyé. Si l'envoi
// échoue, le geste reste en file et repart au retour du réseau ou à la
// prochaine ouverture de l'application. En classe, où le wifi de l'école
// décroche, l'enseignant ne perd donc jamais une évaluation — alors qu'avant,
// un échec se soldait par un `console.log` et un écran qui ne bougeait pas.
//
// `localStorage` et non IndexedDB : l'écriture y est SYNCHRONE, donc terminée
// avant que le gestionnaire de clic ne rende la main. Une application tuée
// juste après l'appui conserve le geste, ce qu'une transaction IndexedDB,
// asynchrone, ne garantit pas. Quelques dizaines d'octets par geste ne
// justifient pas davantage de machinerie.
//
// Rejouer est sans danger : `WorkPlanSkillsController#eval_update` AFFECTE un
// statut, il n'incrémente rien. Une spec d'idempotence verrouille cette
// propriété côté serveur.

const CLE = "ensemble.evaluations_en_attente.v1";
const ATTENTES = [2000, 5000, 15000, 30000, 60000];
const EVENEMENT = "eval-queue:change";

export const ETATS = {
  RAS: "ras", // rien en attente
  HORS_LIGNE: "hors_ligne", // le réseau ne répond pas, on retente seul
  ENVOI: "envoi", // envoi en cours
  REFUS: "refus", // le serveur a répondu non : retenter seul n'y changera rien
  SESSION: "session", // Devise nous a déconnecté
};

function jeton() {
  return document.querySelector('meta[name="csrf-token"]')?.content;
}

export class EvalQueue {
  constructor({ storage = window.localStorage, cible = document } = {}) {
    this.storage = storage;
    this.cible = cible;
    this.etat = ETATS.RAS;
    this.echecs = 0;
    this.minuteur = null;
    this.envoiEnCours = false;
    this.entrees = this.lire();
  }

  // --- persistance ------------------------------------------------------

  // Le stockage peut lever — navigation privée, quota dépassé. On préfère
  // continuer en mémoire plutôt que de faire échouer le clic de l'enseignant :
  // le geste part quand même, il ne survivrait simplement pas à une fermeture.
  lire() {
    try {
      return JSON.parse(this.storage.getItem(CLE)) || [];
    } catch {
      return [];
    }
  }

  ecrire() {
    try {
      this.storage.setItem(CLE, JSON.stringify(this.entrees));
    } catch {
      /* on garde la file en mémoire */
    }
  }

  // --- file -------------------------------------------------------------

  get enAttente() {
    return this.entrees.length;
  }

  // Dédoublonné par compétence : si l'enseignant se ravise avant que le réseau
  // revienne, on n'envoie que son dernier choix, pas la succession de ses
  // hésitations.
  ajouter({ id, url, statut }) {
    this.entrees = this.entrees.filter((entree) => entree.id !== id);
    this.entrees.push({ id, url, statut });
    this.ecrire();
    this.echecs = 0;
    this.notifier(ETATS.ENVOI);
    this.envoyer();
  }

  // --- envoi ------------------------------------------------------------

  async envoyer() {
    if (this.envoiEnCours) return;
    if (this.entrees.length === 0) return this.notifier(ETATS.RAS);

    this.envoiEnCours = true;
    this.annulerReprise();
    this.notifier(ETATS.ENVOI);

    try {
      while (this.entrees.length > 0) {
        const entree = this.entrees[0];
        const issue = await this.transmettre(entree);

        if (issue.etat !== "ok") {
          this.echouer(issue.etat);
          return;
        }

        this.entrees = this.entrees.filter((autre) => autre !== entree);
        this.ecrire();
        this.cible.dispatchEvent(
          new CustomEvent("eval-queue:enregistre", { detail: { id: entree.id, html: issue.html } })
        );
      }
      this.echecs = 0;
      this.notifier(ETATS.RAS);
    } finally {
      this.envoiEnCours = false;
    }
  }

  async transmettre(entree) {
    let reponse;
    try {
      reponse = await fetch(entree.url, {
        method: "PATCH",
        credentials: "same-origin",
        headers: { "X-CSRF-Token": jeton(), Accept: "text/html" },
      });
    } catch {
      // fetch ne rejette que sur une panne réseau : c'est le seul signal fiable
      // de « hors connexion ». `navigator.onLine`, lui, répond `true` sur un
      // wifi d'école associé mais qui ne route plus.
      return { etat: ETATS.HORS_LIGNE };
    }

    // Devise redirige un visiteur déconnecté vers la page de connexion, et
    // `fetch` suit la redirection : sans ce test on prendrait la page de login
    // pour un enregistrement réussi.
    if (reponse.redirected && /\/users\/sign_in/.test(reponse.url)) {
      return { etat: ETATS.SESSION };
    }
    if (reponse.status === 401) return { etat: ETATS.SESSION };
    if (!reponse.ok) return { etat: ETATS.REFUS };

    return { etat: "ok", html: await reponse.text() };
  }

  // Seule une panne réseau se retente toute seule. Un refus du serveur ou une
  // session expirée ne se résoudront pas en attendant : on le dit, et on laisse
  // la main à l'enseignant.
  echouer(etat) {
    this.notifier(etat);
    if (etat !== ETATS.HORS_LIGNE) return;

    const attente = ATTENTES[Math.min(this.echecs, ATTENTES.length - 1)];
    this.echecs += 1;
    this.minuteur = setTimeout(() => this.envoyer(), attente);
  }

  annulerReprise() {
    if (this.minuteur) clearTimeout(this.minuteur);
    this.minuteur = null;
  }

  // Reprise déclenchée par l'enseignant, après un refus du serveur.
  reessayer() {
    this.echecs = 0;
    this.envoyer();
  }

  // --- diffusion --------------------------------------------------------

  notifier(etat) {
    this.etat = etat;
    this.cible.dispatchEvent(
      new CustomEvent(EVENEMENT, { detail: { etat, enAttente: this.enAttente } })
    );
  }
}

// Une seule file pour toute l'application : deux instances se disputeraient le
// même stockage et enverraient chacune les gestes de l'autre.
export const file = new EvalQueue();

// `online` n'est qu'un déclencheur pour retenter plus tôt, jamais un verdict.
window.addEventListener("online", () => file.envoyer());
// Au retour dans l'application — onglet réactivé, PWA rouverte — on repart.
document.addEventListener("visibilitychange", () => {
  if (!document.hidden) file.envoyer();
});
