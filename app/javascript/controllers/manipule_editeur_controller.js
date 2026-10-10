import { Controller } from "@hotwired/stimulus"

// L'éditeur d'un problème : montrer ou cacher ce qui dépend du mode de réponse
// et de l'outil, et tenir l'aperçu à jour pendant qu'on écrit.
//
// Un CONTRÔLEUR, et non plus un fichier chargé par une balise `<script>` sur
// sa seule page. Cette balise a cassé trois fois, toujours pour la même
// raison : un module ES ne s'exécute QU'UNE fois par adresse. Turbo réinsère
// bien la balise, le navigateur ne la rejoue pas.
//
//   — à la première visite Turbo vers l'éditeur, le module s'exécutait APRÈS
//     que `turbo:load` ait été émis : rien ne se branchait, l'aperçu restait
//     blanc (et seulement pour la PREMIÈRE manipulation de chaque session, ce
//     qui le rendait invisible dès qu'on réessayait) ;
//   — au rendu 422 qui suit une validation refusée, Turbo remplace la page
//     sans émettre `turbo:load` du tout : l'éditeur revenait mort.
//
// `connect()` ne connaît pas ces cas particuliers : Stimulus l'appelle chaque
// fois que l'élément apparaît dans le DOM, quelle que soit la façon dont il y
// est arrivé. D'où aussi la disparition du garde par marque et du nettoyage
// sur `turbo:before-cache` : il n'y a plus de double branchement possible.
export default class extends Controller {
  static targets = ["formulaire", "apercu", "agrandir"]
  static values = { attente: { type: Number, default: 400 } }

  connect() {
    // Les aperçus se bousculent dès qu'on rafraîchit sans attendre : deux
    // requêtes partent coup sur coup, et rien ne garantit l'ordre des
    // réponses. Sans ce compteur, la plus ANCIENNE pouvait arriver en dernier
    // et réafficher un aperçu périmé — on voyait sa modification s'effacer.
    this.rang = 0
    this.minuteur = null

    this.basculer()
    this.brancherLesCases()
    this.rafraichir()
  }

  disconnect() {
    clearTimeout(this.minuteur)
  }

  // Pendant qu'on TAPE, on attend une pause : rafraîchir à chaque lettre
  // enverrait trente requêtes pour un énoncé, et l'aperçu clignoterait.
  saisie() {
    this.basculer()
    clearTimeout(this.minuteur)
    this.minuteur = setTimeout(() => this.rafraichir(), this.attenteValue)
  }

  // Un changement DISCRET — une liste, un bouton radio, un champ qu'on quitte
  // — n'a aucune raison d'attendre : le geste est fini, le résultat doit
  // suivre tout de suite.
  changement() {
    this.basculer()
    clearTimeout(this.minuteur)
    this.rafraichir()
  }

  // L'aperçu prend toute la largeur, le formulaire passe dessous. La colonne
  // de droite fait quatre cents pixels, l'écran d'un élève neuf cents : un
  // outil de manipulation n'y tient pas, et le rétrécir jusqu'à ce qu'il y
  // tienne serait le dessiner pour le mauvais écran.
  agrandir() {
    const grand = this.element.classList.toggle("m-editeur-grand")
    if (this.hasAgrandirTarget) this.agrandirTarget.textContent = grand ? "Réduire" : "Agrandir"
  }

  basculer() {
    if (!this.hasFormulaireTarget) return

    const formulaire = this.formulaireTarget
    const choix = formulaire.querySelector("[name='probleme[answer_mode]']:checked")?.value === "choix"
    const outil = formulaire.querySelector("[data-m-outil]")?.value

    formulaire.querySelectorAll("[data-m-si-choix]").forEach((bloc) => { bloc.hidden = !choix })
    formulaire.querySelectorAll("[data-m-si-saisie]").forEach((bloc) => { bloc.hidden = choix })
    // Un bloc de réglages par outil, montré quand c'est le sien. `data-m-si`
    // porte le nom de l'outil : ajouter un outil n'ajoute pas une ligne ici.
    formulaire.querySelectorAll("[data-m-si]").forEach((bloc) => { bloc.hidden = bloc.dataset.mSi !== outil })
    // Le réglage commun à tous les outils : visible dès qu'il y en a un.
    formulaire.querySelectorAll("[data-m-si-outil]").forEach((bloc) => { bloc.hidden = !outil })
  }

  async rafraichir() {
    if (!this.hasFormulaireTarget || !this.hasApercuTarget) return

    const formulaire = this.formulaireTarget

    // On réutilise les champs du formulaire, mais pas ce qui appartient à SON
    // action. Deux pièges, tous deux rencontrés :
    //
    //   — `authenticity_token` est lié à l'action du formulaire, celle qui
    //     enregistre. Envoyé ailleurs, il est invalide et Rails répond 422.
    //     On présente à la place le jeton global de la page.
    //   — `_method` vaut « patch » sur le formulaire de modification. Laissé
    //     là, Rails lit un PATCH sur une adresse qui n'accepte que POST, et
    //     répond 404 — l'aperçu restait blanc à l'édition, jamais à la
    //     création.
    const champs = new FormData(formulaire)
    champs.delete("authenticity_token")
    champs.delete("_method")
    const jeton = document.querySelector("meta[name='csrf-token']")?.content

    const mien = ++this.rang

    try {
      const reponse = await fetch(formulaire.dataset.apercu, {
        method: "POST",
        body: champs,
        headers: { Accept: "text/html", "X-CSRF-Token": jeton || "" },
        credentials: "same-origin",
      })
      if (!reponse.ok) return

      const page = await reponse.text()
      if (mien !== this.rang) return // une demande plus récente est partie depuis

      // `srcdoc` plutôt qu'une adresse : la réponse est déjà la page entière,
      // et on évite un second aller-retour. Les adresses d'assets y sont
      // absolues.
      this.apercuTarget.srcdoc = page
    } catch {
      // Un aperçu qui ne se rafraîchit pas ne doit jamais empêcher d'enregistrer.
    }
  }

  // Les cases de l'outil s'ajoutent et se retirent. Trois fentes figées était
  // arbitraire : deux suffisent souvent, et un problème de partage en demande
  // parfois quatre. Le plafond vient du modèle, qui le fait respecter de son
  // côté — une adresse forgée ne doit pas pouvoir en poser cinquante.
  brancherLesCases() {
    if (!this.hasFormulaireTarget) return

    const formulaire = this.formulaireTarget
    const liste = formulaire.querySelector("[data-m-cases]")
    const ajouter = formulaire.querySelector("[data-m-ajouter-case]")
    if (!liste || !ajouter) return

    const plafond = Number(ajouter.dataset.max) || 6

    const compter = () => {
      const cases = liste.querySelectorAll("[data-m-case]")
      ajouter.hidden = cases.length >= plafond
      // On ne retire jamais la dernière : sans case, l'outil n'a plus de sens.
      cases.forEach((bloc) => {
        bloc.querySelector("[data-m-retirer-case]").hidden = cases.length <= 1
      })
    }

    const retirer = (bouton) => {
      bouton.addEventListener("click", () => {
        bouton.closest("[data-m-case]").remove()
        compter()
        this.changement()
      })
    }

    ajouter.addEventListener("click", () => {
      const cases = liste.querySelectorAll("[data-m-case]")
      if (cases.length >= plafond) return

      const copie = cases[cases.length - 1].cloneNode(true)
      const champ = copie.querySelector("input")
      champ.value = ""
      champ.placeholder = "Ex. Le sac de Lila"
      champ.setAttribute("aria-label", `Nom de la case ${cases.length + 1}`)
      retirer(copie.querySelector("[data-m-retirer-case]"))
      liste.appendChild(copie)
      compter()
      champ.focus()
      this.changement()
    })

    liste.querySelectorAll("[data-m-retirer-case]").forEach(retirer)
    compter()
  }
}
