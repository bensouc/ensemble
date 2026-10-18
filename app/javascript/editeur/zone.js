// Éditeur d'une zone de manipulation (Figure::Zone). Le matériel s'y pose et s'y
// déplace librement, aimanté à une grille d'un quart d'em ; un élément s'agrandit
// par son coin, la zone aussi. « Valider » rend la description de la zone —
// `80x24-b10.4.8_p2.20.8.150` : sa taille, puis chaque élément, sa place en pas de
// grille et, s'il n'est pas à 100 %, sa taille —, que le serveur change en figure
// (POST /figures, kind « zone »).
//
// Chargé à la demande par editeur_enonce_controller, avec le catalogue du
// matériel (GET /figures/materiel) : le vrai dessin et la taille de chaque élément.

// La zone d'une figure, lue dans son sgid : `…/Figure/zone-80x24-b10.4.8`. Le sgid
// est signé, pas chiffré ; on n'en lit que l'identifiant.
export function lireZone(attachment) {
  try {
    const sgid = JSON.parse(attachment).sgid
    const encode = sgid.slice(0, sgid.lastIndexOf("--")).replace(/-/g, "+").replace(/_/g, "/")
    const match = atob(encode).match(/Figure\/zone-(\d+)x(\d+)(?:-([a-z0-9._]+))?/)
    if (!match) return null
    const elements = (match[3] || "").split("_").filter(Boolean).map((texte) => {
      const [code, x, y, taille] = texte.split(".")
      return { code, x: Number(x), y: Number(y), taille: Number(taille || 100) }
    })
    return { largeur: Number(match[1]), hauteur: Number(match[2]), elements }
  } catch {
    return null
  }
}

export const ZONE_NEUVE = { largeur: 80, hauteur: 24, elements: [] }

// Taille d'un élément, en % de celle du matériel : par crans de 10 (Figure::Zone::TAILLES).
const TAILLE_MIN = 50
const TAILLE_MAX = 400
const CRAN = 10

const borner = (v, min, max) => Math.min(Math.max(v, min), max)

export class EditeurDeZone {
  constructor({ hote, catalogue, zone, taillePolice, surValider }) {
    this.hote = hote
    this.catalogue = catalogue
    this.largeur = zone.largeur
    this.hauteur = zone.hauteur
    // Un code inconnu du catalogue (matériel retiré depuis) est laissé de côté.
    this.elements = zone.elements.filter((e) => catalogue.elements[e.code]).map((e) => ({ taille: 100, ...e }))
    this.taillePolice = taillePolice
    this.surValider = surValider
    this.choisi = null
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
    this.ajusterLoupe()
    this.dessiner()
    this.racine.focus()
    // La fenêtre peut ne pas avoir encore sa largeur : la loupe se recalcule ensuite.
    requestAnimationFrame(() => {
      if (!this.racine) return
      this.ajusterLoupe()
      this.dessiner()
    })
  }

  fermer() {
    this.racine?.remove()
    this.racine = null
  }

  gabarit() {
    const palette = Object.entries(this.catalogue.elements).map(([code, e]) =>
      `<button type="button" class="rt-materiel__choix" data-ajouter="${code}" title="${e.libelle}"
               aria-label="Ajouter : ${e.libelle}"><img src="${e.image}" alt="" style="height: ${borner(e.hauteur * 4, 26, 44)}px"></button>`
    ).join("")
    return `<div class="rt-zone__panneau">
      <div class="rt-zone__entete">
        <div class="rt-zone__palette">${palette}</div>
        <span class="rt-zone__choix" aria-live="polite"></span>
        <button type="button" class="ui-btn ui-btn--neutral ui-btn--sm" data-retirer disabled><span>Retirer l'élément</span></button>
      </div>
      <div class="rt-zone__defilement"><div class="rt-zone__cadre"><span class="rt-zone__poignee" title="Agrandir la zone"></span></div></div>
      <p class="rt-zone__aide">Glissez le matériel pour le placer, tirez le rond de son coin pour l'agrandir. Clavier : flèches pour ajuster, + et − pour la taille, Suppr. pour retirer.</p>
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

  // La place d'un élément, en pas de grille, à sa taille.
  dimensions(e) {
    const modele = this.catalogue.elements[e.code]
    return { largeur: (modele.largeur * e.taille) / 100, hauteur: (modele.hauteur * e.taille) / 100 }
  }

  // Le cadre est grossi (×2 au plus) pour placer le matériel avec précision, dans
  // la largeur de la fenêtre : l'énoncé, lui, le montrera à sa vraie taille. Pas
  // pendant un glisser : la poignée ne suivrait plus la souris.
  ajusterLoupe() {
    const police = parseFloat(this.taillePolice)
    const place = this.racine.querySelector(".rt-zone__defilement").clientWidth - 16
    this.loupe = Math.max(1, Math.min(2, place / (this.largeur * this.catalogue.pas * police)))
  }

  dessiner() {
    this.cadre.style.fontSize = `${parseFloat(this.taillePolice) * this.loupe}px`
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
      img.classList.toggle("rt-zone__element--choisi", index === this.choisi)
      this.cadre.append(img)
      if (index === this.choisi) {
        const poignee = document.createElement("span")
        poignee.className = "rt-zone__agrandir"
        poignee.title = `Agrandir (${e.taille} %)`
        Object.assign(poignee.style, { left: this.em(e.x + largeur), top: this.em(e.y + hauteur) })
        this.cadre.append(poignee)
      }
    })
    this.racine.querySelector("[data-retirer]").disabled = this.choisi === null
    // L'élément choisi, et sa taille : à gauche de « Retirer l'élément ».
    const choisi = this.elements[this.choisi]
    this.racine.querySelector(".rt-zone__choix").textContent =
      choisi ? `${this.catalogue.elements[choisi.code].libelle} · ${choisi.taille} %` : ""
    const plein = this.elements.length >= this.catalogue.elementsAuPlus
    this.racine.querySelectorAll("[data-ajouter]").forEach((b) => { b.disabled = plein })
  }

  // --- Actions ------------------------------------------------------------------

  onClic(event) {
    const bouton = event.target.closest("button")
    if (!bouton) return
    if (bouton.dataset.ajouter) this.ajouter(bouton.dataset.ajouter)
    else if (bouton.hasAttribute("data-retirer")) this.retirer()
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
    this.choisi = this.elements.length - 1
    this.ajusterLoupe()
    this.dessiner()
  }

  retirer() {
    if (this.choisi === null) return
    this.elements.splice(this.choisi, 1)
    this.choisi = null
    this.dessiner()
  }

  // Agrandit l'élément choisi, ou le réduit, d'autant de crans ; la zone grandit
  // avec lui s'il le faut.
  changerTaille(e, taille) {
    e.taille = borner(Math.round(taille / CRAN) * CRAN, TAILLE_MIN, TAILLE_MAX)
    const { largeur, hauteur } = this.dimensions(e)
    this.agrandirPour(e.x + largeur, e.y + hauteur)
    Object.assign(e, this.dansLaZone(e, e.x, e.y))
  }

  async valider() {
    const elements = this.elements.map((e) => `${e.code}.${e.x}.${e.y}${e.taille === 100 ? "" : `.${e.taille}`}`).join("_")
    const ok = await this.surValider(`${this.largeur}x${this.hauteur}${elements ? `-${elements}` : ""}`)
    if (ok) return this.fermer()
    const erreur = this.racine.querySelector(".rt-zone__erreur")
    erreur.textContent = "La zone n'a pas pu être enregistrée. Réessayez."
    erreur.hidden = false
  }

  // La zone s'étend pour contenir ce bord (bas droit), dans ses limites.
  agrandirPour(droite, bas) {
    const [, largeurMax] = this.catalogue.largeurs
    const [, hauteurMax] = this.catalogue.hauteurs
    this.largeur = borner(Math.max(this.largeur, Math.ceil(droite) + 1), this.largeur, largeurMax)
    this.hauteur = borner(Math.max(this.hauteur, Math.ceil(bas) + 1), this.hauteur, hauteurMax)
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
    if (event.key === "Escape") {
      event.preventDefault()
      return this.fermer()
    }
    if (this.choisi === null) return
    const e = this.elements[this.choisi]
    if (event.key === "Delete" || event.key === "Backspace") {
      event.preventDefault()
      return this.retirer()
    }
    if (["+", "=", "-", "_"].includes(event.key)) {
      event.preventDefault()
      this.changerTaille(e, e.taille + (["+", "="].includes(event.key) ? CRAN : -CRAN))
      this.ajusterLoupe()
      return this.dessiner()
    }
    const pas = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] }[event.key]
    if (!pas) return
    event.preventDefault()
    Object.assign(e, this.dansLaZone(e, e.x + pas[0], e.y + pas[1]))
    this.dessiner()
  }

  // --- Glisser : un élément, son coin, ou celui de la zone ---------------------------

  pasEnPixels() {
    return parseFloat(getComputedStyle(this.cadre).fontSize) * this.catalogue.pas
  }

  onAppui(event) {
    const deplacer = this.geste(event.target)
    if (!deplacer) {
      this.choisi = null
      return this.dessiner()
    }
    event.preventDefault()
    const pas = this.pasEnPixels()
    const depart = { x: event.clientX, y: event.clientY }
    const bouger = (ev) => {
      deplacer(Math.round((ev.clientX - depart.x) / pas), Math.round((ev.clientY - depart.y) / pas))
      this.dessiner()
    }
    const lacher = () => {
      window.removeEventListener("pointermove", bouger)
      window.removeEventListener("pointerup", lacher)
      if (!this.racine) return
      this.ajusterLoupe()
      this.dessiner()
      this.racine.focus()
    }
    window.addEventListener("pointermove", bouger)
    window.addEventListener("pointerup", lacher)
    this.dessiner()
  }

  // Ce que fait un glisser selon où il commence ; rien hors d'un élément ou d'une poignée.
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
    this.choisi = Number(element.dataset.index)
    const e = this.elements[this.choisi]
    const debut = { x: e.x, y: e.y }
    return (dx, dy) => Object.assign(e, this.dansLaZone(e, debut.x + dx, debut.y + dy))
  }

  // La zone ne rétrécit pas au point de couper un élément.
  redimensionner(largeur, hauteur) {
    const [largeurMin, largeurMax] = this.catalogue.largeurs
    const [hauteurMin, hauteurMax] = this.catalogue.hauteurs
    const bords = this.elements.map((e) => {
      const { largeur: l, hauteur: h } = this.dimensions(e)
      return [Math.ceil(e.x + l), Math.ceil(e.y + h)]
    })
    this.largeur = borner(largeur, Math.max(largeurMin, ...bords.map((b) => b[0])), largeurMax)
    this.hauteur = borner(hauteur, Math.max(hauteurMin, ...bords.map((b) => b[1])), hauteurMax)
  }
}
