import { Controller } from "@hotwired/stimulus";
import { file, ETATS } from "../eval_queue";

// Le bandeau qui dit à l'enseignant où en sont ses évaluations.
//
// Le silence veut dire « tout est enregistré » : un bandeau permanent devient
// du bruit qu'on n'attribue plus. Il n'apparaît donc que lorsqu'il y a quelque
// chose à signaler, et se referme seul une fois la file vidée.
//
// Trois échecs sont distingués, parce qu'annoncer « ce sera envoyé au retour du
// réseau » serait faux dans deux cas sur trois : un refus du serveur ou une
// session expirée ne se résoudront pas en attendant.
const MESSAGES = {
  [ETATS.HORS_LIGNE]: ({ enAttente }) =>
    enAttente > 0
      ? `Hors connexion — ${compte(enAttente)} en attente. ${promesse(enAttente)}`
      : "Hors connexion. Vos évaluations seront envoyées dès le retour du réseau.",
  [ETATS.ENVOI]: ({ enAttente }) => `Envoi de ${compte(enAttente)}…`,
  [ETATS.REFUS]: ({ enAttente }) => `${compte(enAttente)} ${refus(enAttente)}`,
  [ETATS.SESSION]: ({ enAttente }) =>
    `Votre session a expiré. Reconnectez-vous pour envoyer ${compte(enAttente)}.`,
};

// Les accords se font au singulier comme au pluriel : « 1 évaluation en
// attente. Elle seront envoyées » se lisait dans le bandeau.
function compte(nombre) {
  return nombre > 1 ? `${nombre} évaluations` : `${nombre} évaluation`;
}

function promesse(nombre) {
  return nombre > 1
    ? "Elles seront envoyées au retour du réseau."
    : "Elle sera envoyée au retour du réseau.";
}

function refus(nombre) {
  return nombre > 1 ? "n'ont pas pu être enregistrées." : "n'a pas pu être enregistrée.";
}

export default class extends Controller {
  static targets = ["message", "reessayer"];

  connect() {
    this.surChangement = (event) => this.rendre(event.detail);
    document.addEventListener("eval-queue:change", this.surChangement);
    // Des gestes peuvent dormir en file depuis la session précédente.
    this.rendre({ etat: file.etat, enAttente: file.enAttente });
    if (file.enAttente > 0) file.envoyer();
  }

  disconnect() {
    document.removeEventListener("eval-queue:change", this.surChangement);
  }

  reessayer() {
    file.reessayer();
  }

  rendre({ etat, enAttente }) {
    // Plus rien en file : on confirme brièvement, puis on s'efface. Sans ce
    // mot de la fin, l'enseignant reste avec un doute.
    if (etat === ETATS.RAS) return this.conclure(enAttente);

    this.annulerFermeture();
    const message = MESSAGES[etat];
    if (!message) return this.cacher();

    this.afficher(message({ enAttente }), { etat, reessayable: etat === ETATS.REFUS });
  }

  conclure() {
    if (!this.visible) return this.cacher();

    this.afficher("Tout est enregistré.", { etat: "ok", reessayable: false });
    this.fermeture = setTimeout(() => this.cacher(), 3000);
  }

  afficher(texte, { etat, reessayable }) {
    this.visible = true;
    this.element.hidden = false;
    this.element.dataset.etat = etat;
    if (this.hasMessageTarget) this.messageTarget.textContent = texte;
    if (this.hasReessayerTarget) this.reessayerTarget.hidden = !reessayable;
  }

  cacher() {
    this.visible = false;
    this.element.hidden = true;
    if (this.hasReessayerTarget) this.reessayerTarget.hidden = true;
  }

  annulerFermeture() {
    if (this.fermeture) clearTimeout(this.fermeture);
    this.fermeture = null;
  }
}
