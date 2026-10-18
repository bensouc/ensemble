// Éditeur d'une zone de manipulation (Figure::Zone). Le matériel s'y pose et s'y
// déplace librement, aimanté à une grille d'un quart d'em ; la zone s'agrandit par
// son coin. « Valider » rend la description de la zone — `80x24-b10.4.8_p2.20.8` :
// sa taille, puis chaque élément et sa place, en pas de grille —, que le serveur
// change en figure (POST /figures, kind « zone »).
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
      const [code, x, y] = texte.split(".")
      return { code, x: Number(x), y: Number(y) }
    })
    return { largeur: Number(match[1]), hauteur: Number(match[2]), elements }
  } catch {
    return null
  }
}

export const ZONE_NEUVE = { largeur: 80, hauteur: 24, elements: [] }

const borner = (v, min, max) => Math.min(Math.max(v, min), max)

export class EditeurDeZone {
  constructor({ hote, catalogue, zone, taillePolice, surValider }) {
    this.hote = hote
    this.catalogue = catalogue
    this.largeur = zone.largeur
    this.hauteur = zone.hauteur
    // Un code inconnu du catalogue (matériel retiré depuis) est laissé de côté.
    this.elements = zone.elements.filter((e) => catalogue.elements[e.code]).map((e) => ({ ...e }))
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
      <div class="rt-zone__palette">${palette}</div>
      <div class="rt-zone__defilement"><div class="rt-zone__cadre"><span class="rt-zone__poignee" title="Agrandir la zone"></span></div></div>
      <p class="rt-zone__aide">Glissez le matériel pour le placer. Suppr. retire l'élément choisi, les flèches l'ajustent ; le coin agrandit la zone.</p>
      <p class="rt-zone__erreur" hidden></p>
      <div class="rt-zone__pied">
        <button type="button" class="ui-btn ui-btn--neutral ui-btn--sm" data-retirer disabled><span>Retirer l'élément</span></button>
        <span class="rt-zone__espace"></span>
        <button type="button" class="ui-btn ui-btn--neutral ui-btn--sm" data-annuler><span>Annuler</span></button>
        <button type="button" class="ui-btn ui-btn--primary ui-btn--sm" data-valider><span>Valider</span></button>
      </div>
    </div>`
  }

  // --- Rendu --------------------------------------------------------------------

  em(pas) {
    return `${pas * this.catalogue.pas}em`
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
    this.cadre.querySelectorAll(".rt-zone__element").forEach((n) => n.remove())
    this.elements.forEach((e, index) => {
      const modele = this.catalogue.elements[e.code]
      const img = document.createElement("img")
      img.className = "rt-zone__element"
      img.src = modele.image
      img.alt = modele.libelle
      img.draggable = false
      img.dataset.index = index
      Object.assign(img.style, {
        left: this.em(e.x), top: this.em(e.y), width: this.em(modele.largeur), height: this.em(modele.hauteur)
      })
      img.classList.toggle("rt-zone__element--choisi", index === this.choisi)
      this.cadre.append(img)
    })
    this.racine.querySelector("[data-retirer]").disabled = this.choisi === null
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
    const modele = this.catalogue.elements[code]
    const dernier = this.elements.at(-1)
    let x = 1
    let y = 1
    if (dernier) {
      const precedent = this.catalogue.elements[dernier.code]
      x = Math.ceil(dernier.x + precedent.largeur) + 1
      y = dernier.y
      if (x + modele.largeur > this.largeur) {
        x = 1
        y = Math.ceil(Math.max(...this.elements.map((e) => e.y + this.catalogue.elements[e.code].hauteur))) + 1
      }
    }
    const [, largeurMax] = this.catalogue.largeurs
    const [, hauteurMax] = this.catalogue.hauteurs
    this.largeur = borner(Math.max(this.largeur, Math.ceil(x + modele.largeur) + 1), this.largeur, largeurMax)
    this.hauteur = borner(Math.max(this.hauteur, Math.ceil(y + modele.hauteur) + 1), this.hauteur, hauteurMax)
    this.elements.push({ code, ...this.dansLaZone(code, x, y) })
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

  async valider() {
    const elements = this.elements.map((e) => `${e.code}.${e.x}.${e.y}`).join("_")
    const ok = await this.surValider(`${this.largeur}x${this.hauteur}${elements ? `-${elements}` : ""}`)
    if (ok) return this.fermer()
    const erreur = this.racine.querySelector(".rt-zone__erreur")
    erreur.textContent = "La zone n'a pas pu être enregistrée. Réessayez."
    erreur.hidden = false
  }

  // Le coin haut gauche d'un élément, ramené dans la zone.
  dansLaZone(code, x, y) {
    const modele = this.catalogue.elements[code]
    return {
      x: borner(Math.round(x), 0, Math.max(0, Math.floor(this.largeur - modele.largeur))),
      y: borner(Math.round(y), 0, Math.max(0, Math.floor(this.hauteur - modele.hauteur)))
    }
  }

  onTouche(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      return this.fermer()
    }
    if (this.choisi === null) return
    if (event.key === "Delete" || event.key === "Backspace") {
      event.preventDefault()
      return this.retirer()
    }
    const pas = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] }[event.key]
    if (!pas) return
    event.preventDefault()
    const e = this.elements[this.choisi]
    Object.assign(e, this.dansLaZone(e.code, e.x + pas[0], e.y + pas[1]))
    this.dessiner()
  }

  // --- Glisser : un élément, ou le coin de la zone ---------------------------------

  pasEnPixels() {
    return parseFloat(getComputedStyle(this.cadre).fontSize) * this.catalogue.pas
  }

  onAppui(event) {
    const poignee = event.target.closest(".rt-zone__poignee")
    const element = event.target.closest(".rt-zone__element")
    if (!poignee && !element) {
      this.choisi = null
      return this.dessiner()
    }
    event.preventDefault()
    const pas = this.pasEnPixels()
    const depart = { x: event.clientX, y: event.clientY }
    let deplacer
    if (poignee) {
      const debut = { largeur: this.largeur, hauteur: this.hauteur }
      deplacer = (dx, dy) => this.redimensionner(debut.largeur + dx, debut.hauteur + dy)
    } else {
      this.choisi = Number(element.dataset.index)
      const e = this.elements[this.choisi]
      const debut = { x: e.x, y: e.y }
      deplacer = (dx, dy) => Object.assign(e, this.dansLaZone(e.code, debut.x + dx, debut.y + dy))
    }
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

  // La zone ne rétrécit pas au point de couper un élément.
  redimensionner(largeur, hauteur) {
    const [largeurMin, largeurMax] = this.catalogue.largeurs
    const [hauteurMin, hauteurMax] = this.catalogue.hauteurs
    const bords = this.elements.map((e) => {
      const m = this.catalogue.elements[e.code]
      return [Math.ceil(e.x + m.largeur), Math.ceil(e.y + m.hauteur)]
    })
    this.largeur = borner(largeur, Math.max(largeurMin, ...bords.map((b) => b[0])), largeurMax)
    this.hauteur = borner(hauteur, Math.max(hauteurMin, ...bords.map((b) => b[1])), hauteurMax)
  }
}
