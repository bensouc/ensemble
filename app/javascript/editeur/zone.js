// Éditeur d'une zone de manipulation (Figure::Zone). Le matériel s'y pose et s'y
// déplace librement, aimanté à une grille d'un quart d'em ; un élément s'agrandit
// par son coin, la zone aussi. Plusieurs éléments se choisissent ensemble (Maj +
// clic, ou un cadre tracé dans la zone) pour être déplacés, dupliqués ou retirés
// d'un coup. « Valider » resserre le cadre sur le matériel et rend la
// description de la zone —
// `80x24-b10.4.8_p2.20.8.150` : sa taille, puis chaque élément, sa place en pas de
// grille et, s'il n'est pas à 100 %, sa taille —, que le serveur change en figure
// (POST /figures, kind « zone »).
//
// Chargé à la demande par editeur_enonce_controller, avec le catalogue du
// matériel (GET /figures/materiel) : le vrai dessin et la taille de chaque élément,
// et les limites de Figure::Zone.
import { idDeLaFigure } from "./types"

// La zone d'une figure, lue dans son identifiant : `zone-80x24-b10.4.8`.
export function lireZone(attachment) {
  const match = /^zone-(\d+)x(\d+)(?:-([a-z0-9._]+))?$/.exec(idDeLaFigure(attachment) || "")
  if (!match) return null
  const elements = (match[3] || "").split("_").map((texte) => {
    const [code, x, y, taille] = texte.split(".")
    return { code, x: Number(x), y: Number(y), taille: Number(taille || 100) }
  })
  return { largeur: Number(match[1]), hauteur: Number(match[2]), elements }
}

// La description d'une zone, telle que POST /figures l'attend.
function decrireZone({ largeur, hauteur, elements }) {
  const decrits = elements.map((e) => `${e.code}.${e.x}.${e.y}${e.taille === 100 ? "" : `.${e.taille}`}`).join("_")
  return `${largeur}x${hauteur}${decrits ? `-${decrits}` : ""}`
}

// Les éléments que le catalogue connaît : un matériel retiré depuis est laissé de côté.
function elementsConnus(catalogue, elements) {
  return elements.filter((e) => catalogue.elements[e.code]).map((e) => ({ ...e }))
}

// La place d'un élément, en pas de grille, à sa taille.
function dimensions(catalogue, e) {
  const modele = catalogue.elements[e.code]
  return { largeur: (modele.largeur * e.taille) / 100, hauteur: (modele.hauteur * e.taille) / 100 }
}

// Le cadre d'une zone, dans les limites du catalogue : il ne rétrécit pas au
// point de couper un élément.
function cadreBorne(catalogue, elements, largeur, hauteur) {
  const [largeurMin, largeurMax] = catalogue.largeurs
  const [hauteurMin, hauteurMax] = catalogue.hauteurs
  const bords = elements.map((e) => {
    const { largeur: l, hauteur: h } = dimensions(catalogue, e)
    return [Math.ceil(e.x + l), Math.ceil(e.y + h)]
  })
  return {
    largeur: borner(largeur, Math.max(largeurMin, ...bords.map((b) => b[0])), largeurMax),
    hauteur: borner(hauteur, Math.max(hauteurMin, ...bords.map((b) => b[1])), hauteurMax)
  }
}

// Taille d'un élément, en % de celle du matériel, par crans.
const CRAN = 10
const PAS_DU_CLAVIER = { "+": CRAN, "=": CRAN, "-": -CRAN, "_": -CRAN }
const FLECHES = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] }
// La palette : une rangée par sorte de matériel.
const RANGEES = [["Billets", "billet"], ["Pièces", "piece"], ["Numération", "bloc"]]

function borner(v, min, max) { return Math.min(Math.max(v, min), max) }

export class EditeurDeZone {
  constructor({ hote, catalogue, zone, taillePolice, surValider }) {
    this.hote = hote
    this.catalogue = catalogue
    this.largeur = zone.largeur
    this.hauteur = zone.hauteur
    this.elements = elementsConnus(catalogue, zone.elements)
    this.police = parseFloat(taillePolice)
    this.surValider = surValider
    // Les index des éléments choisis.
    this.choisis = []
  }

  // L'élément choisi quand il est seul : lui seul a une poignée et sa taille écrite.
  get choisi() {
    return this.choisis.length === 1 ? this.choisis[0] : null
  }

  ouvrir() {
    this.racine = document.createElement("div")
    this.racine.className = "rt-zone"
    this.racine.setAttribute("role", "dialog")
    this.racine.setAttribute("aria-label", "Zone de manipulation")
    this.racine.tabIndex = -1
    this.racine.innerHTML = this.gabarit()
    this.hote.append(this.racine)
    this.cadre = this.racine.querySelector(".rt-zone__cadre")
    this.racine.addEventListener("click", (e) => this.onClic(e))
    this.racine.addEventListener("keydown", (e) => this.onTouche(e))
    this.cadre.addEventListener("pointerdown", (e) => this.onAppui(e))
    this.dessiner()
    this.racine.focus()
    // La fenêtre peut ne pas avoir encore sa largeur : la loupe se recalcule ensuite.
    requestAnimationFrame(() => this.racine && this.dessiner())
  }

  fermer() {
    this.racine?.remove()
    this.racine = null
  }

  // La palette, une rangée par sorte : billets, pièces, blocs de numération. Le
  // matériel de chaque rangée s'aligne après les titres, même quand il passe à la
  // ligne.
  gabarit() {
    const rangee = ([titre, sorte]) => {
      const choix = Object.entries(this.catalogue.elements).filter(([, e]) => e.sorte === sorte).map(([code, e]) =>
        `<button type="button" class="rt-materiel__choix" data-ajouter="${code}" title="${e.libelle}"
                 aria-label="Ajouter : ${e.libelle}"><img src="${e.image}" alt="" style="height: ${borner(e.hauteur * 4, 26, 44)}px"></button>`
      ).join("")
      return `<div class="rt-zone__palette" role="group" aria-label="${titre}"><span class="rt-zone__titre">${titre}</span><div class="rt-zone__tuiles">${choix}</div></div>`
    }
    return `<div class="rt-zone__panneau">
      <div class="rt-zone__entete">
        <div class="rt-zone__palettes">${RANGEES.map(rangee).join("")}</div>
        <div class="rt-zone__selection">
          <div class="rt-zone__actions">
            <button type="button" class="ui-btn ui-btn--neutral ui-btn--sm" data-dupliquer disabled><i class="fa-solid fa-clone" aria-hidden="true"></i><span>Dupliquer</span></button>
            <button type="button" class="ui-btn ui-btn--neutral ui-btn--sm" data-retirer disabled><i class="fa-solid fa-trash-can" aria-hidden="true"></i><span class="rt-zone__retirer">Retirer l'élément</span></button>
          </div>
          <span class="rt-zone__choix" aria-live="polite"></span>
        </div>
      </div>
      <div class="rt-zone__defilement"><div class="rt-zone__cadre"><span class="rt-zone__poignee" title="Agrandir la zone"></span></div></div>
      <p class="rt-zone__aide">Glissez le matériel pour le placer, tirez le rond de son coin pour l'agrandir. Maj + clic, ou un cadre tracé dans la zone, pour en choisir plusieurs. Clavier : flèches pour déplacer, + et − pour la taille, Suppr. pour retirer, Ctrl+D (⌘D) pour dupliquer, Ctrl+A (⌘A) pour tout choisir.</p>
      <p class="rt-zone__erreur" hidden></p>
      <div class="rt-zone__pied">
        <button type="button" class="ui-btn ui-btn--neutral ui-btn--sm" data-annuler><span>Annuler</span></button>
        <button type="button" class="ui-btn ui-btn--primary ui-btn--sm" data-valider><span>Valider</span></button>
      </div>
    </div>`
  }

  // --- Rendu --------------------------------------------------------------------

  em(pas) {
    return `${pas * this.catalogue.pas}em`
  }

  dimensions(e) {
    return dimensions(this.catalogue, e)
  }

  // Le cadre est grossi (×2 au plus) pour placer le matériel avec précision, dans
  // la largeur de la fenêtre : l'énoncé, lui, le montrera à sa vraie taille. Pas
  // pendant un glisser : la poignée ne suivrait plus la souris.
  dessiner() {
    if (!this.enGeste) {
      const place = this.racine.querySelector(".rt-zone__defilement").clientWidth - 16
      this.loupe = borner(place / (this.largeur * this.catalogue.pas * this.police), 1, 2)
    }
    this.cadre.style.fontSize = `${this.police * this.loupe}px`
    this.cadre.style.width = this.em(this.largeur)
    this.cadre.style.height = this.em(this.hauteur)
    this.cadre.querySelectorAll(".rt-zone__element, .rt-zone__agrandir").forEach((n) => n.remove())
    this.elements.forEach((e, index) => {
      const modele = this.catalogue.elements[e.code]
      const { largeur, hauteur } = this.dimensions(e)
      const img = document.createElement("img")
      img.className = "rt-zone__element"
      img.src = modele.image
      img.alt = modele.libelle
      img.draggable = false
      img.dataset.index = index
      Object.assign(img.style, { left: this.em(e.x), top: this.em(e.y), width: this.em(largeur), height: this.em(hauteur) })
      img.classList.toggle("rt-zone__element--choisi", this.choisis.includes(index))
      this.cadre.append(img)
      if (index === this.choisi) {
        const poignee = document.createElement("span")
        poignee.className = "rt-zone__agrandir"
        poignee.title = `Agrandir (${e.taille} %)`
        Object.assign(poignee.style, { left: this.em(e.x + largeur), top: this.em(e.y + hauteur) })
        this.cadre.append(poignee)
      }
    })
    const nombre = this.choisis.length
    this.racine.querySelector("[data-retirer]").disabled = nombre === 0
    this.racine.querySelector(".rt-zone__retirer").textContent = nombre > 1 ? `Retirer les ${nombre} éléments` : "Retirer l'élément"
    this.racine.querySelector("[data-dupliquer]").disabled = nombre === 0 || !this.placePour(nombre)
    // Sous les boutons : l'élément choisi et sa taille, ou le nombre d'éléments choisis.
    const seul = this.elements[this.choisi]
    this.racine.querySelector(".rt-zone__choix").textContent =
      seul ? `${this.catalogue.elements[seul.code].libelle} · ${seul.taille} %` : nombre > 1 ? `${nombre} éléments` : ""
    this.racine.querySelectorAll("[data-ajouter]").forEach((b) => { b.disabled = !this.placePour(1) })
  }

  // --- Actions ------------------------------------------------------------------

  onClic(event) {
    const bouton = event.target.closest("button")
    if (!bouton) return
    if (bouton.dataset.ajouter) this.ajouter(bouton.dataset.ajouter)
    else if (bouton.hasAttribute("data-retirer")) this.retirer()
    else if (bouton.hasAttribute("data-dupliquer")) this.dupliquer()
    else if (bouton.hasAttribute("data-annuler")) this.fermer()
    else if (bouton.hasAttribute("data-valider")) this.valider()
  }

  // Le nouvel élément se range à droite du dernier posé, ou à la ligne en dessous
  // quand la place manque ; la zone grandit si besoin.
  ajouter(code) {
    const nouveau = { code, x: 1, y: 1, taille: 100 }
    const { largeur, hauteur } = this.dimensions(nouveau)
    const dernier = this.elements.at(-1)
    if (dernier) {
      nouveau.x = Math.ceil(dernier.x + this.dimensions(dernier).largeur) + 1
      nouveau.y = dernier.y
      if (nouveau.x + largeur > this.largeur) {
        nouveau.x = 1
        nouveau.y = Math.ceil(Math.max(...this.elements.map((e) => e.y + this.dimensions(e).hauteur))) + 1
      }
    }
    this.agrandirPour(nouveau.x + largeur, nouveau.y + hauteur)
    this.elements.push({ ...nouveau, ...this.dansLaZone(nouveau, nouveau.x, nouveau.y) })
    this.choisis = [this.elements.length - 1]
    this.dessiner()
  }

  // La zone peut-elle recevoir autant d'éléments de plus ?
  placePour(nombre) {
    return this.elements.length + nombre <= this.catalogue.elementsAuPlus
  }

  retirer() {
    if (!this.choisis.length) return
    this.elements = this.elements.filter((_, index) => !this.choisis.includes(index))
    this.choisis = []
    this.dessiner()
  }

  // Les éléments choisis, recopiés à droite de leur groupe — dessous quand la zone
  // ne peut plus s'élargir ; la zone grandit pour eux, et les copies deviennent la
  // sélection.
  dupliquer() {
    const originaux = this.choisis.map((index) => this.elements[index])
    if (!originaux.length || !this.placePour(originaux.length)) return
    const groupe = this.boite(originaux)
    const [largeur, hauteur] = [Math.ceil(groupe.droite - groupe.gauche) + 1, Math.ceil(groupe.bas - groupe.haut) + 1]
    const [dx, dy] = groupe.droite + largeur < this.catalogue.largeurs[1] ? [largeur, 0] : [0, hauteur]
    const copies = originaux.map((e) => ({ ...e, x: e.x + dx, y: e.y + dy }))
    this.agrandirPour(groupe.droite + dx, groupe.bas + dy)
    this.choisis = copies.map((_, n) => this.elements.length + n)
    this.elements.push(...copies)
    // La zone n'a pas pu grandir assez : les copies sont ramenées dedans, d'un bloc.
    this.deplacerLeGroupe(copies.map((e) => ({ ...e })), 0, 0)
    this.dessiner()
  }

  // Le rectangle qui contient des éléments, en pas de grille.
  boite(elements) {
    const bords = elements.map((e) => ({ e, ...this.dimensions(e) }))
    return {
      gauche: Math.min(...bords.map(({ e }) => e.x)),
      haut: Math.min(...bords.map(({ e }) => e.y)),
      droite: Math.max(...bords.map(({ e, largeur }) => e.x + largeur)),
      bas: Math.max(...bords.map(({ e, hauteur }) => e.y + hauteur))
    }
  }

  // Déplace les éléments choisis d'un bloc, depuis leurs places de `depart` : le
  // groupe s'arrête tout entier dès que l'un d'eux touche un bord.
  deplacerLeGroupe(depart, dx, dy) {
    const { gauche, haut, droite, bas } = this.boite(depart)
    const decalage = [
      borner(dx, -gauche, Math.floor(this.largeur - droite)),
      borner(dy, -haut, Math.floor(this.hauteur - bas))
    ]
    this.choisis.forEach((index, n) => {
      Object.assign(this.elements[index], { x: depart[n].x + decalage[0], y: depart[n].y + decalage[1] })
    })
  }

  // Agrandit l'élément choisi, ou le réduit, d'autant de crans ; la zone grandit
  // avec lui s'il le faut.
  changerTaille(e, taille) {
    e.taille = borner(Math.round(taille / CRAN) * CRAN, ...this.catalogue.tailles)
    const { largeur, hauteur } = this.dimensions(e)
    this.agrandirPour(e.x + largeur, e.y + hauteur)
    Object.assign(e, this.dansLaZone(e, e.x, e.y))
  }

  // La zone telle qu'elle s'enregistre : le matériel ramené dans le coin haut
  // gauche, et le cadre resserré sur lui. L'énoncé, l'affichage et le PDF
  // montrent ainsi la zone sans vide autour, tous les trois pareils. Une zone
  // vide garde son cadre.
  zoneAjustee() {
    if (!this.elements.length) return this
    const gauche = Math.min(...this.elements.map((e) => e.x))
    const haut = Math.min(...this.elements.map((e) => e.y))
    const elements = this.elements.map((e) => ({ ...e, x: e.x - gauche, y: e.y - haut }))
    return { elements, ...cadreBorne(this.catalogue, elements, 0, 0) }
  }

  async valider() {
    const ok = await this.surValider(decrireZone(this.zoneAjustee()))
    if (ok) return this.fermer()
    const erreur = this.racine.querySelector(".rt-zone__erreur")
    erreur.textContent = "La zone n'a pas pu être enregistrée. Réessayez."
    erreur.hidden = false
  }

  // La zone s'étend pour contenir ce bord (bas droit), dans ses limites.
  agrandirPour(droite, bas) {
    this.redimensionner(Math.max(this.largeur, Math.ceil(droite) + 1), Math.max(this.hauteur, Math.ceil(bas) + 1))
  }

  // Le coin haut gauche d'un élément, ramené dans la zone.
  dansLaZone(e, x, y) {
    const { largeur, hauteur } = this.dimensions(e)
    return {
      x: borner(Math.round(x), 0, Math.max(0, Math.floor(this.largeur - largeur))),
      y: borner(Math.round(y), 0, Math.max(0, Math.floor(this.hauteur - hauteur)))
    }
  }

  onTouche(event) {
    const commande = event.metaKey || event.ctrlKey
    const touche = event.key.toLowerCase()
    if (event.key === "Escape") {
      event.preventDefault()
      // Échap défait d'abord la sélection, puis ferme la fenêtre.
      if (!this.choisis.length) return this.fermer()
      this.choisis = []
      return this.dessiner()
    }
    if (commande && touche === "a") {
      event.preventDefault()
      this.choisis = this.elements.map((_, index) => index)
      return this.dessiner()
    }
    if (!this.choisis.length) return
    if (commande && touche === "d") {
      event.preventDefault()
      return this.dupliquer()
    }
    if (event.key === "Delete" || event.key === "Backspace") {
      event.preventDefault()
      return this.retirer()
    }
    if (PAS_DU_CLAVIER[event.key]) {
      event.preventDefault()
      this.choisis.forEach((index) => {
        const e = this.elements[index]
        this.changerTaille(e, e.taille + PAS_DU_CLAVIER[event.key])
      })
      return this.dessiner()
    }
    const pas = FLECHES[event.key]
    if (!pas) return
    event.preventDefault()
    this.deplacerLeGroupe(this.choisis.map((index) => ({ ...this.elements[index] })), ...pas)
    this.dessiner()
  }

  // --- Glisser : un élément, son coin, ou celui de la zone ---------------------------

  pasEnPixels() {
    return parseFloat(getComputedStyle(this.cadre).fontSize) * this.catalogue.pas
  }

  onAppui(event) {
    const ajout = event.shiftKey || event.metaKey || event.ctrlKey
    const element = event.target.closest(".rt-zone__element")
    // Maj + clic : l'élément entre dans la sélection, ou en sort ; rien ne bouge.
    if (element && ajout) {
      const index = Number(element.dataset.index)
      this.choisis = this.choisis.includes(index) ? this.choisis.filter((i) => i !== index) : [...this.choisis, index]
      return this.dessiner()
    }
    const deplacer = this.geste(event.target)
    if (!deplacer) return this.debutCadreDeSelection(event, ajout)
    event.preventDefault()
    const pas = this.pasEnPixels()
    const depart = { x: event.clientX, y: event.clientY }
    let dernier = ""
    this.enGeste = true
    const bouger = (ev) => {
      const dx = Math.round((ev.clientX - depart.x) / pas)
      const dy = Math.round((ev.clientY - depart.y) / pas)
      // La souris bouge plus souvent qu'elle ne change de case.
      if (`${dx},${dy}` === dernier) return
      dernier = `${dx},${dy}`
      deplacer(dx, dy)
      this.dessiner()
    }
    const lacher = () => {
      window.removeEventListener("pointermove", bouger)
      window.removeEventListener("pointerup", lacher)
      this.enGeste = false
      if (!this.racine) return
      this.dessiner()
      this.racine.focus()
    }
    window.addEventListener("pointermove", bouger)
    window.addEventListener("pointerup", lacher)
    this.dessiner()
  }

  // Ce que fait un glisser selon où il commence ; hors d'un élément ou d'une
  // poignée, il trace un cadre de sélection (debutCadreDeSelection).
  geste(cible) {
    if (cible.closest(".rt-zone__poignee")) {
      const debut = { largeur: this.largeur, hauteur: this.hauteur }
      return (dx, dy) => this.redimensionner(debut.largeur + dx, debut.hauteur + dy)
    }
    if (cible.closest(".rt-zone__agrandir")) {
      const e = this.elements[this.choisi]
      const debut = { taille: e.taille, largeur: this.dimensions(e).largeur }
      // La largeur suit la souris, la hauteur suit la largeur : les proportions restent.
      return (dx) => this.changerTaille(e, (debut.taille * (debut.largeur + dx)) / debut.largeur)
    }
    const element = cible.closest(".rt-zone__element")
    if (!element) return null
    // Un élément hors de la sélection la remplace ; un élément choisi emmène tout
    // le groupe.
    const index = Number(element.dataset.index)
    if (!this.choisis.includes(index)) this.choisis = [index]
    const depart = this.choisis.map((i) => ({ ...this.elements[i] }))
    return (dx, dy) => this.deplacerLeGroupe(depart, dx, dy)
  }

  // Un cadre tracé dans la zone choisit tous les éléments qu'il touche ; avec Maj,
  // il les ajoute à la sélection. Un simple clic défait la sélection.
  debutCadreDeSelection(event, ajout) {
    event.preventDefault()
    const avant = ajout ? [...this.choisis] : []
    const origine = this.cadre.getBoundingClientRect()
    const pas = this.pasEnPixels()
    const depart = { x: event.clientX - origine.left, y: event.clientY - origine.top }
    const trace = document.createElement("span")
    trace.className = "rt-zone__lasso"
    this.cadre.append(trace)
    this.enGeste = true
    this.choisis = avant
    this.dessiner()

    const suivre = (ev) => {
      const x = borner(ev.clientX - origine.left, 0, origine.width)
      const y = borner(ev.clientY - origine.top, 0, origine.height)
      const [gauche, droite] = [Math.min(depart.x, x), Math.max(depart.x, x)]
      const [haut, bas] = [Math.min(depart.y, y), Math.max(depart.y, y)]
      Object.assign(trace.style, { left: `${gauche}px`, top: `${haut}px`, width: `${droite - gauche}px`, height: `${bas - haut}px` })
      const touches = this.elements.flatMap((e, index) => {
        const { largeur, hauteur } = this.dimensions(e)
        const touche = e.x * pas < droite && (e.x + largeur) * pas > gauche && e.y * pas < bas && (e.y + hauteur) * pas > haut
        return touche ? [index] : []
      })
      this.choisis = [...new Set([...avant, ...touches])]
      this.dessiner()
    }
    const lacher = () => {
      window.removeEventListener("pointermove", suivre)
      window.removeEventListener("pointerup", lacher)
      trace.remove()
      this.enGeste = false
      if (!this.racine) return
      this.dessiner()
      this.racine.focus()
    }
    window.addEventListener("pointermove", suivre)
    window.addEventListener("pointerup", lacher)
  }

  redimensionner(largeur, hauteur) {
    Object.assign(this, cadreBorne(this.catalogue, this.elements, largeur, hauteur))
  }
}
