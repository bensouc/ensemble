// Pièce jointe ActionText dans TipTap : image, figure (Seyès, horloge, picto),
// tableau maison non converti.
//
// Le nœud ne comprend rien de son contenu : il recopie tel quel le format que
// Rails échange avec Trix — `<figure data-trix-attachment='{json}'
// data-trix-attributes='{json}'>` — que Rails reconvertit en
// <action-text-attachment> à l'enregistrement (même approche que Rhino Editor).
//
// La taille et la position vivent dans `presentation` (data-trix-attributes),
// comme avec Trix : « taille-33 gauche ». La taille est libre (10 à 100 % de la
// largeur), réglée par la poignée ou les boutons ; à gauche et à droite, la
// pièce flotte et le texte, ou une autre image, vient à côté. Voir
// FigurePresentation côté serveur, qui rend exactement les mêmes classes.
import { Node } from "@tiptap/core"
import { FIGURE_TYPE, ZONE_TYPE, lireJson } from "./types"

const TAILLES = [
  { valeur: "25", libelle: "¼", titre: "Un quart de la largeur" },
  { valeur: "50", libelle: "½", titre: "La moitié de la largeur" },
  { valeur: "75", libelle: "¾", titre: "Trois quarts de la largeur" },
  { valeur: "100", libelle: "Pleine", titre: "Toute la largeur" }
]

// Gauche et droite habillent : le texte, ou une autre image, vient à côté.
const POSITIONS = [
  { valeur: "gauche", titre: "À gauche, le texte à côté",
    trace: '<rect x="3" y="5" width="8" height="8" rx="1.5"/><path d="M14 6h7M14 10h7M14 14h5M3 18.5h18"/>' },
  { valeur: "centre", titre: "Centrée, seule sur sa ligne",
    trace: '<rect x="8" y="4" width="8" height="8" rx="1.5"/><path d="M3 16h18M3 20h18"/>' },
  { valeur: "droite", titre: "À droite, le texte à côté",
    trace: '<rect x="13" y="5" width="8" height="8" rx="1.5"/><path d="M3 6h7M3 10h7M5 14h5M3 18.5h18"/>' }
]

const TAILLE_MIN = 10

export function presentationEnParties(presentation) {
  const match = /^taille-(\d+)(?: (gauche|centre|droite))?$/.exec(presentation || "")
  if (!match) return [null, null]
  const taille = Math.min(100, Math.max(TAILLE_MIN, parseInt(match[1], 10)))
  return [String(taille), match[2] || null]
}

export const PieceJointe = Node.create({
  name: "pieceJointe",
  group: "inline",
  inline: true,
  atom: true,
  selectable: true,
  draggable: true,

  addAttributes() {
    return {
      attachment: { default: null, parseHTML: (el) => el.getAttribute("data-trix-attachment") },
      attributes: { default: null, parseHTML: (el) => el.getAttribute("data-trix-attributes") },
      // Rails ne pose pas `data-trix-content-type` sur ce qu'il donne à l'éditeur
      // (`to_trix_html`) : le type est dans le JSON de la pièce. Sans ce repli,
      // une figure rouverte n'était plus reconnue, ni redimensionnable.
      contentType: {
        default: null,
        parseHTML: (el) => el.getAttribute("data-trix-content-type") || lireJson(el.getAttribute("data-trix-attachment")).contentType || null
      }
    }
  },

  parseHTML() {
    return [{ tag: "figure[data-trix-attachment]" }]
  },

  renderHTML({ node }) {
    const attrs = { "data-trix-attachment": node.attrs.attachment }
    if (node.attrs.attributes) attrs["data-trix-attributes"] = node.attrs.attributes
    if (node.attrs.contentType) attrs["data-trix-content-type"] = node.attrs.contentType
    return ["figure", attrs]
  },

  addNodeView() {
    return ({ node, editor, getPos }) => new VuePieceJointe(node, editor, getPos)
  }
})

// Affichage dans l'éditeur, avec la barre de taille quand la pièce est
// sélectionnée. Mêmes classes et mêmes attributs que le <figure> de Trix : les
// styles de trix/_figures.scss (taille, habillage, Seyès collées) s'appliquent.
class VuePieceJointe {
  constructor(node, editor, getPos) {
    this.editor = editor
    this.getPos = getPos
    this.dom = document.createElement("figure")
    this.dom.contentEditable = "false"
    // Glisser la pièce la déplace dans l'énoncé (ProseMirror gère le dépôt).
    this.dom.draggable = true
    // Un double-clic sur une zone de manipulation l'ouvre, comme « Modifier la zone ».
    this.dom.addEventListener("dblclick", () => { if (this.estZone) this.signaler("modifier-zone") })
    this.rendre(node)
  }

  rendre(node) {
    this.node = node
    const piece = lireJson(node.attrs.attachment)
    this.piece = piece
    const type = piece.content ? "content" : (piece.previewable || /^image\//.test(piece.contentType || "") ? "preview" : "file")
    this.type = type

    this.dom.className = `attachment attachment--${type}`
    this.dom.setAttribute("data-trix-content-type", node.attrs.contentType || piece.contentType || "")
    if (node.attrs.attributes) this.dom.setAttribute("data-trix-attributes", node.attrs.attributes)
    else this.dom.removeAttribute("data-trix-attributes")

    // Le contenu ne change qu'avec la pièce elle-même : ne pas le reconstruire
    // à chaque changement de taille (une image rechargerait).
    if (this.contenuDe !== node.attrs.attachment) {
      this.contenuDe = node.attrs.attachment
      this.dom.innerHTML = ""
      if (piece.content) {
        // Rendu d'édition produit par notre serveur (figures/_editor, tables/_editor).
        this.dom.insertAdjacentHTML("afterbegin", piece.content)
      } else if (type === "preview" && piece.url) {
        const img = document.createElement("img")
        img.src = piece.url
        img.alt = piece.filename || ""
        if (piece.width) img.width = piece.width
        if (piece.height) img.height = piece.height
        this.dom.appendChild(img)
      } else {
        const nom = document.createElement("span")
        nom.className = "attachment__name"
        nom.textContent = piece.filename || "Pièce jointe"
        this.dom.appendChild(nom)
      }
    }
    this.appliquerTaille()
    if (this.barre) this.afficherBarre()
  }

  // Taille et position : mêmes classes que l'affichage (FigurePresentation).
  appliquerTaille() {
    let [taille, position] = presentationEnParties(lireJson(this.node.attrs.attributes).presentation)
    // Une horloge sans taille prend un quart de la largeur, comme à l'affichage.
    if (!taille && this.estHorloge) [taille, position] = ["25", "gauche"]
    this.dom.classList.toggle("rt-fig", !!taille)
    ;["gauche", "centre", "droite"].forEach((p) => this.dom.classList.toggle(`rt-fig--${p}`, !!taille && p === position))
    this.dom.style.width = taille ? `${taille}%` : ""
  }

  update(node) {
    if (node.type.name !== "pieceJointe") return false
    this.rendre(node)
    return true
  }

  selectNode() {
    this.dom.classList.add("rt-piece--selectionnee")
    this.afficherBarre()
  }

  deselectNode() {
    this.dom.classList.remove("rt-piece--selectionnee")
    this.barre?.remove()
    this.barre = null
    this.poignee?.remove()
    this.poignee = null
  }

  // Barre et poignée sont à nous : ProseMirror n'a ni à les lire ni à réagir à
  // leurs clics (sinon tirer la poignée lancerait un glisser-déposer).
  stopEvent(event) {
    return [this.barre, this.poignee].some((el) => el && el.contains(event.target))
  }

  ignoreMutation() {
    return true
  }

  // La part de la ligne qu'une zone prend d'elle-même, en % : sa taille de départ
  // quand on l'aligne sans l'avoir agrandie.
  tailleNaturelle() {
    const part = (100 * this.dom.getBoundingClientRect().width) / this.dom.parentElement.clientWidth
    return String(Math.min(100, Math.max(TAILLE_MIN, Math.round(part))))
  }

  // « Changer l'heure », « Modifier la zone » : le contrôleur de l'éditeur s'en charge.
  signaler(nom) {
    this.dom.dispatchEvent(new CustomEvent(`piece-jointe:${nom}`, {
      bubbles: true, detail: { pos: this.getPos(), attachment: this.node.attrs.attachment }
    }))
  }

  // --- Barre de taille et de position --------------------------------------------

  get typeDeContenu() {
    return this.node.attrs.contentType || this.piece.contentType
  }

  get estRedimensionnable() {
    return this.type === "preview" || [FIGURE_TYPE, ZONE_TYPE].includes(this.typeDeContenu)
  }

  get estHorloge() {
    return !!this.dom.querySelector(".rt-figure-img--horloge")
  }

  get estZone() {
    return this.typeDeContenu === ZONE_TYPE
  }

  afficherBarre() {
    this.barre?.remove()
    const barre = document.createElement("div")
    barre.className = "rt-piece-barre"
    barre.contentEditable = "false"

    let html = ""
    if (this.estRedimensionnable) {
      const [taille, position] = presentationEnParties(lireJson(this.node.attrs.attributes).presentation)
      // Une zone a sa largeur à elle : pas de ¼ ½ ¾, seulement l'alignement ; la
      // poignée l'agrandit ou la réduit tout entière.
      const tailleCourante = taille || (this.estZone ? null : this.estHorloge ? "25" : "100")
      // Une taille libre (33 %) n'enfonce aucun des boutons ¼ ½ ¾.
      const positionCourante = position || (tailleCourante && tailleCourante !== "100" ? "gauche" : null)
      this.tailleCourante = tailleCourante
      this.positionCourante = positionCourante
      if (!this.estZone) {
        html += TAILLES.map(({ valeur, libelle, titre }) =>
          `<button type="button" class="rt-fig-bar__btn" data-taille="${valeur}" title="${titre}"
                   aria-pressed="${valeur === tailleCourante}">${libelle}</button>`).join("")
        html += '<span class="rt-fig-bar__sep" aria-hidden="true"></span>'
      }
      html += POSITIONS.map(({ valeur, titre, trace }) =>
        `<button type="button" class="rt-fig-bar__btn" data-position="${valeur}" title="${titre}" aria-label="${titre}"
                 aria-pressed="${valeur === positionCourante}" ${tailleCourante === "100" ? "disabled" : ""}>
           <svg viewBox="0 0 24 24" aria-hidden="true">${trace}</svg></button>`).join("")
      if (this.estHorloge) {
        html += '<span class="rt-fig-bar__sep" aria-hidden="true"></span><button type="button" class="rt-fig-bar__btn" data-heure>Changer l\'heure</button>'
      }
      if (this.estZone) {
        html += '<span class="rt-fig-bar__sep" aria-hidden="true"></span><button type="button" class="rt-fig-bar__btn" data-zone>Modifier la zone</button>'
      }
      html += '<span class="rt-fig-bar__sep" aria-hidden="true"></span>'
    }
    html += '<button type="button" class="rt-fig-bar__btn" data-supprimer title="Supprimer" aria-label="Supprimer">✕</button>'

    barre.innerHTML = `<span class="rt-fig-bar" role="group" aria-label="Pièce jointe">${html}</span>`
    // Le clic ne doit pas retirer la sélection de la pièce jointe.
    barre.addEventListener("mousedown", (e) => e.preventDefault())
    barre.addEventListener("click", (e) => this.clicBarre(e))
    this.dom.prepend(barre)
    this.barre = barre
    if (this.estRedimensionnable) this.afficherPoignee()
  }

  // --- Poignée : la taille à la souris ---------------------------------------------

  afficherPoignee() {
    this.poignee?.remove()
    const poignee = document.createElement("span")
    // En bas à droite ; en bas à gauche pour une pièce calée à droite, qui
    // grandit vers la gauche.
    poignee.className = `rt-piece-poignee${this.positionCourante === "droite" ? " rt-piece-poignee--gauche" : ""}`
    poignee.title = "Tirer pour changer la taille"
    poignee.draggable = false
    poignee.addEventListener("pointerdown", (e) => this.debutRedimension(e))
    poignee.addEventListener("dragstart", (e) => e.preventDefault())
    this.dom.appendChild(poignee)
    this.poignee = poignee
  }

  // La largeur suit le pointeur, en pourcentage de la largeur de l'énoncé,
  // arrondie à 5 % près ; elle n'est enregistrée qu'au relâchement. Elle se
  // mesure depuis le bord qui ne bouge pas : le gauche, le droit pour une pièce
  // calée à droite, le milieu pour une pièce centrée.
  debutRedimension(event) {
    event.preventDefault()
    event.stopPropagation()
    // Sinon le navigateur lance le glisser-déposer de la pièce entière (elle est
    // déplaçable) et la poignée ne reçoit plus le mouvement.
    this.dom.draggable = false
    const largeurEnonce = this.editor.view.dom.getBoundingClientRect().width
    const cadre = this.dom.getBoundingClientRect()
    const largeurDepuis = {
      droite: (x) => cadre.right - x,
      centre: (x) => 2 * (x - (cadre.left + cadre.width / 2))
    }[this.positionCourante] || ((x) => x - cadre.left)
    let taille = this.tailleCourante || this.tailleNaturelle()
    const mesure = document.createElement("span")
    mesure.className = "rt-piece-mesure"
    this.dom.appendChild(mesure)
    this.dom.classList.add("rt-fig")

    // Suivi sur la fenêtre, pas sur la poignée : l'éditeur peut redessiner la
    // pièce sur l'appui, et une capture posée sur l'ancienne poignée se perd.
    const suivre = (e) => {
      const brute = (largeurDepuis(e.clientX) / largeurEnonce) * 100
      taille = String(Math.min(100, Math.max(TAILLE_MIN, Math.round(brute / 5) * 5)))
      this.dom.style.width = `${taille}%`
      mesure.textContent = `${taille} %`
    }
    const fin = () => {
      window.removeEventListener("pointermove", suivre)
      window.removeEventListener("pointerup", fin)
      window.removeEventListener("pointercancel", fin)
      mesure.remove()
      this.dom.draggable = true
      // Une image qu'on redimensionne se cale à gauche : c'est ce qui en met
      // plusieurs sur une même ligne.
      this.redimensionner(taille, this.positionCourante || "gauche")
    }
    window.addEventListener("pointermove", suivre)
    window.addEventListener("pointerup", fin)
    window.addEventListener("pointercancel", fin)
  }

  clicBarre(event) {
    const bouton = event.target.closest("button")
    if (!bouton) return
    event.preventDefault()

    if (bouton.hasAttribute("data-supprimer")) {
      const pos = this.getPos()
      this.editor.chain().focus().deleteRange({ from: pos, to: pos + 1 }).run()
    } else if (bouton.dataset.taille) {
      this.redimensionner(bouton.dataset.taille, this.positionCourante || "centre")
    } else if (bouton.dataset.position) {
      this.redimensionner(this.tailleCourante || this.tailleNaturelle(), bouton.dataset.position)
    } else if (bouton.hasAttribute("data-zone")) {
      this.signaler("modifier-zone")
    } else if (bouton.hasAttribute("data-heure")) {
      this.signaler("changer-heure")
    }
  }

  // « Pleine » rend à une image sa présentation d'origine, « gallery » : celle
  // que Trix lui donnait.
  redimensionner(taille, position) {
    const presentation = String(taille) === "100" && this.type === "preview" ? "gallery" : `taille-${taille} ${position}`
    const attributs = { ...lireJson(this.node.attrs.attributes), presentation }
    const pos = this.getPos()
    this.editor.chain().command(({ tr }) => {
      tr.setNodeMarkup(pos, undefined, { ...this.node.attrs, attributes: JSON.stringify(attributs) })
      return true
    }).setNodeSelection(pos).run()
  }

  destroy() {
    this.barre?.remove()
    this.poignee?.remove()
  }
}
