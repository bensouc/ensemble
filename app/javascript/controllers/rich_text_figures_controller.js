import { Controller } from "@hotwired/stimulus"
import Trix from "trix"
import { post } from "@rails/request.js"

// Figures de l'énoncé : lignes Seyès, horloge, pictogrammes ; et la barre de
// taille et de position commune aux images et aux figures.
//
// Deux points d'accroche, tous deux posés sur le champ (comme rich-text-table) :
//
//   - le menu « Figure » est ajouté au groupe file-tools de la toolbar à
//     `trix-initialize` ;
//   - la barre de taille est ajoutée à la petite toolbar que Trix affiche
//     au-dessus d'une pièce jointe sélectionnée (`trix-attachment-before-toolbar`).
//
// La taille et la position s'écrivent dans l'attribut `presentation` de la pièce
// jointe (« taille-50 centre ») : c'est le seul attribut libre qu'ActionText
// conserve. Voir FigurePresentation côté serveur.
const FIGURE_TYPE = "application/vnd.ensemble.figure"

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

// Mêmes tracés que Figure::DESSINS (app/models/figure.rb), pour les boutons du menu.
const CERCLE = "M12 2a10 10 0 1 0 0.01 0z"
const PICTOS = [
  ["coche", "Coche", [[CERCLE, "#4CAF50"], ["M7 12.5l3.5 3.5L17 9", null, "#fff", 2.6]]],
  ["croix", "Croix", [[CERCLE, "#CE3E1B"], ["M8.5 8.5l7 7M15.5 8.5l-7 7", null, "#fff", 2.6]]],
  ["case", "Case à cocher", [["M4.5 4.5h15v15h-15z", "#fff", "#3D3D3D", 2]]],
  ["crayon", "Écris", [["M4 20l1-5L16 4l4 4L9 19z", "#FFE3CF", "#C44003", 1.6], ["M14 6l4 4", null, "#C44003", 1.6]]],
  ["ciseaux", "Découpe", [["M6.5 4.5a2.5 2.5 0 1 0 .01 0zM6.5 14.5a2.5 2.5 0 1 0 .01 0z", null, "#3D3D3D", 1.6], ["M8.6 8.4L20 17M8.6 15.6L20 7", null, "#3D3D3D", 1.6]]],
  ["loupe", "Observe", [["M10.5 4a6.5 6.5 0 1 0 .01 0z", "#C8E6FB", "#167FFB", 1.8], ["M15.5 15.5L20 20", null, "#167FFB", 2.4]]],
  ["bulle", "Dis-le à voix haute", [["M4 5h16v10H10l-4 4v-4H4z", "#E7E4FA", "#7C5CE7", 1.6]]]
]

function pictoSvg(traits) {
  const paths = traits.map(([d, fill, stroke, width]) =>
    `<path d="${d}" fill="${fill || "none"}" stroke="${stroke || "none"}" stroke-width="${width || 0}" stroke-linecap="round" stroke-linejoin="round"/>`
  ).join("")
  return `<svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">${paths}</svg>`
}

export default class extends Controller {
  connect() {
    this.addMenu = this.addMenu.bind(this)
    this.addSizeBar = this.addSizeBar.bind(this)
    this.onOutsidePointer = this.onOutsidePointer.bind(this)

    this.element.addEventListener("trix-initialize", this.addMenu)
    this.element.addEventListener("trix-attachment-before-toolbar", this.addSizeBar)
    // Trix peut être prêt avant ce contrôleur (navigation Turbo, reconnexion).
    this.addMenu()
  }

  disconnect() {
    this.element.removeEventListener("trix-initialize", this.addMenu)
    this.element.removeEventListener("trix-attachment-before-toolbar", this.addSizeBar)
    document.removeEventListener("pointerdown", this.onOutsidePointer, true)
  }

  // --- Menu « Figure » --------------------------------------------------------

  addMenu() {
    const fileTools = this.element.querySelector("[data-trix-button-group=file-tools]")
    if (!fileTools || fileTools.querySelector(".rt-figures")) return

    const pictos = PICTOS.map(([nom, libelle, traits]) => `
      <button type="button" class="rt-figures__picto" data-picto="${nom}"
              title="${libelle}" aria-label="Insérer le pictogramme « ${libelle} »" tabindex="-1">${pictoSvg(traits)}</button>`).join("")

    fileTools.insertAdjacentHTML("beforeend", `
      <span class="rt-tb__palette rt-figures">
        <button type="button" class="trix-button rt-tb__btn rt-figures__trigger"
                aria-haspopup="dialog" aria-expanded="false"
                title="Insérer une figure" aria-label="Insérer une figure" tabindex="-1">
          <svg class="rt-tb__icon" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3 2"/></svg>
          <span class="visually-hidden">Insérer une figure</span>
        </button>
        <div class="rt-tb__popover rt-figures__panel" role="dialog" aria-label="Insérer une figure" hidden>
          <div class="rt-figures__section">
            <span class="rt-figures__titre">Ligne d'écriture</span>
            <div class="rt-figures__rangee">
              <button type="button" class="rt-figures__choix" data-seyes="sans-marge" tabindex="-1">
                <span class="rt-figures__apercu rt-seyes" aria-hidden="true"></span>Seyès
              </button>
              <button type="button" class="rt-figures__choix" data-seyes="marge" tabindex="-1">
                <span class="rt-figures__apercu rt-seyes rt-seyes--marge" aria-hidden="true"></span>Seyès avec marge
              </button>
              <button type="button" class="rt-figures__choix" data-ligne tabindex="-1">
                <span class="rt-figures__apercu rt-ligne" aria-hidden="true"></span>Ligne simple
              </button>
            </div>
          </div>
          <div class="rt-figures__section">
            <span class="rt-figures__titre">Horloge</span>
            <div class="rt-figures__rangee rt-figures__horloge">
              <input type="text" class="rt-figures__heure" inputmode="numeric" placeholder="3:15"
                     aria-label="Heure de l'horloge, vide pour une horloge sans aiguilles" maxlength="5">
              <label class="rt-figures__case"><input type="checkbox" class="rt-figures__chiffres" checked> Chiffres</label>
              <button type="button" class="rt-figures__inserer" tabindex="-1">Insérer</button>
            </div>
            <span class="rt-figures__aide">Laissez l'heure vide : l'élève dessine les aiguilles.</span>
            <span class="rt-figures__erreur" hidden>Heure non reconnue. Exemple : 3:15</span>
          </div>
          <div class="rt-figures__section">
            <span class="rt-figures__titre">Pictogramme</span>
            <div class="rt-figures__rangee">${pictos}</div>
          </div>
        </div>
      </span>`)

    const menu = fileTools.querySelector(".rt-figures")
    this.menu = menu
    menu.querySelector(".rt-figures__trigger").addEventListener("click", (event) => {
      event.preventDefault()
      this.isOpen ? this.hide() : this.show()
    })
    menu.addEventListener("keydown", (event) => this.keydown(event))
    menu.querySelectorAll("[data-seyes]").forEach((button) => {
      button.addEventListener("click", (event) => {
        event.preventDefault()
        this.insertFigure({ kind: "seyes", marge: button.dataset.seyes === "marge" })
      })
    })
    menu.querySelector("[data-ligne]").addEventListener("click", (event) => {
      event.preventDefault()
      this.insertFigure({ kind: "ligne" })
    })
    menu.querySelectorAll("[data-picto]").forEach((button) => {
      button.addEventListener("click", (event) => {
        event.preventDefault()
        this.insertFigure({ kind: "picto", nom: button.dataset.picto })
      })
    })
    menu.querySelector(".rt-figures__inserer").addEventListener("click", (event) => {
      event.preventDefault()
      this.insertClock()
    })
    menu.querySelector(".rt-figures__heure").addEventListener("keydown", (event) => {
      if (event.key !== "Enter") return
      event.preventDefault()
      this.insertClock()
    })
  }

  show({ focusClock = false } = {}) {
    // Le curseur de l'énoncé, à retrouver après un passage dans le champ de
    // l'heure : y taper sort le focus de l'éditeur.
    this.savedRange = this.editorElement?.editor?.getSelectedRange() || null
    // Un seul popover ouvert à la fois dans la toolbar.
    this.menu.closest("trix-toolbar")?.querySelectorAll(".rt-tb__popover")
      .forEach((panel) => { panel.hidden = true })

    this.panel.hidden = false
    this.trigger.setAttribute("aria-expanded", "true")
    this.menu.querySelector(".rt-figures__erreur").hidden = true
    document.addEventListener("pointerdown", this.onOutsidePointer, true)
    if (focusClock) this.menu.querySelector(".rt-figures__heure").focus()
  }

  hide() {
    if (!this.panel) return
    this.panel.hidden = true
    this.trigger.setAttribute("aria-expanded", "false")
    this.replacing = null
    this.menu.querySelector(".rt-figures__inserer").textContent = "Insérer"
    document.removeEventListener("pointerdown", this.onOutsidePointer, true)
  }

  onOutsidePointer(event) {
    if (!this.menu.contains(event.target)) this.hide()
  }

  keydown(event) {
    if (event.key !== "Escape" || !this.isOpen) return
    event.stopPropagation()
    this.hide()
    this.editorElement?.focus()
  }

  get panel() { return this.menu?.querySelector(".rt-figures__panel") }
  get trigger() { return this.menu?.querySelector(".rt-figures__trigger") }
  get isOpen() { return this.panel && !this.panel.hidden }

  // --- Insertion ----------------------------------------------------------------

  async insertClock() {
    const heure = this.menu.querySelector(".rt-figures__heure").value
    const chiffres = this.menu.querySelector(".rt-figures__chiffres").checked
    const replacing = this.replacing
    const inserted = await this.insertFigure({ kind: "horloge", heure, chiffres }, { replacing })
    if (!inserted) this.menu.querySelector(".rt-figures__erreur").hidden = false
  }

  async insertFigure(params, { replacing = null } = {}) {
    const response = await post("/figures", { body: params, responseKind: "json" })
    if (!response.ok) return false

    const element = this.editorElement
    const editor = element?.editor
    if (!editor) return false

    const attachment = new Trix.Attachment(await response.json)
    let presentation = null

    element.focus()
    if (replacing) {
      // Changer l'heure d'une horloge : la nouvelle prend la place de l'ancienne,
      // à la même taille.
      presentation = this.presentationOf(replacing)
      const range = editor.getDocument().getRangeOfAttachment(replacing)
      if (range) editor.setSelectedRange(range)
    } else {
      if (this.savedRange) editor.setSelectedRange(this.savedRange)
      // Une ligne d'écriture commence toujours une ligne.
      if (params.kind === "seyes" || params.kind === "ligne") this.ensureLineStart(editor)
      if (params.kind === "horloge") presentation = "taille-25 gauche"
    }

    editor.insertAttachment(attachment)
    if (presentation) editor.composition.updateAttributesForAttachment({ presentation }, attachment)
    this.savedRange = null
    if (params.kind === "horloge") this.hide()
    return true
  }

  ensureLineStart(editor) {
    const [start] = editor.getSelectedRange()
    if (start > 0 && editor.getDocument().getCharacterAtPosition(start - 1) !== "\n") {
      editor.insertLineBreak()
    }
  }

  // --- Barre de taille et de position -------------------------------------------

  addSizeBar(event) {
    const { toolbar, attachment } = event
    const isImage = attachment.isPreviewable()
    const isFigure = attachment.getContentType() === FIGURE_TYPE
    if (!toolbar || !(isImage || isFigure)) return

    const figure = toolbar.closest("figure") || toolbar.parentElement
    const [taille, position] = this.parse(this.presentationOf(attachment, figure))
    const tailleCourante = taille || (isFigure && this.isClock(figure) ? "25" : "100")
    const positionCourante = position || (tailleCourante === "100" ? null : "gauche")

    const bar = document.createElement("span")
    bar.className = "rt-fig-bar"
    bar.setAttribute("role", "group")
    bar.setAttribute("aria-label", "Taille et position")
    bar.innerHTML =
      TAILLES.map(({ valeur, libelle, titre }) =>
        `<button type="button" class="rt-fig-bar__btn" data-taille="${valeur}" title="${titre}"
                 aria-pressed="${valeur === tailleCourante}">${libelle}</button>`).join("") +
      '<span class="rt-fig-bar__sep" aria-hidden="true"></span>' +
      POSITIONS.map(({ valeur, titre, trace }) =>
        `<button type="button" class="rt-fig-bar__btn" data-position="${valeur}" title="${titre}" aria-label="${titre}"
                 aria-pressed="${valeur === positionCourante}" ${tailleCourante === "100" ? "disabled" : ""}>
           <svg viewBox="0 0 24 24" aria-hidden="true">${trace}</svg></button>`).join("") +
      (this.isClock(figure)
        ? '<span class="rt-fig-bar__sep" aria-hidden="true"></span><button type="button" class="rt-fig-bar__btn" data-heure>Changer l\'heure</button>'
        : "")

    bar.querySelectorAll("[data-taille]").forEach((button) => {
      button.addEventListener("click", (e) => {
        e.preventDefault()
        this.resize(attachment, isImage, button.dataset.taille, positionCourante || "centre")
      })
    })
    bar.querySelectorAll("[data-position]").forEach((button) => {
      button.addEventListener("click", (e) => {
        e.preventDefault()
        this.resize(attachment, isImage, tailleCourante, button.dataset.position)
      })
    })
    bar.querySelector("[data-heure]")?.addEventListener("click", (e) => {
      e.preventDefault()
      this.editClock(attachment)
    })

    const row = toolbar.querySelector(".trix-button-row") || toolbar
    row.prepend(bar)
  }

  resize(attachment, isImage, taille, position) {
    const editor = this.editorElement?.editor
    if (!editor) return

    // « Pleine » rend à une image sa présentation d'origine, « gallery » : celle
    // que Trix lui donne, et qui la regroupe en galerie avec ses voisines.
    const presentation = taille === "100" && isImage ? "gallery" : `taille-${taille} ${position}`
    editor.recordUndoEntry("Taille de la figure", { consolidatable: false })
    editor.composition.updateAttributesForAttachment({ presentation }, attachment)
    this.refreshAttachment(attachment)
  }

  // Tant que la barre d'une pièce jointe est ouverte, Trix ne reporte AUCUN
  // changement à l'écran (`canSyncDocumentView` est faux pendant l'édition d'une
  // pièce jointe) : la nouvelle taille n'apparaissait qu'à la fermeture. On ferme
  // donc la barre, ce qui redessine, puis on la rouvre sur la même pièce jointe —
  // la barre se reconstruit avec la taille à jour.
  refreshAttachment(attachment) {
    const compositionController = this.editorElement?.editorController?.compositionController
    if (!compositionController) return

    compositionController.uninstallAttachmentEditor()
    compositionController.installAttachmentEditorForAttachment(attachment)
  }

  editClock(attachment) {
    const [heure, chiffres] = this.clockSettings(attachment)
    this.show()
    this.replacing = attachment
    this.menu.querySelector(".rt-figures__heure").value = heure
    this.menu.querySelector(".rt-figures__chiffres").checked = chiffres
    this.menu.querySelector(".rt-figures__inserer").textContent = "Changer l'heure"
    this.menu.querySelector(".rt-figures__heure").focus()
  }

  // Réglages d'une horloge, lus dans son sgid : `…/Figure/horloge-0315-chiffres`.
  // Le sgid n'est pas chiffré, seulement signé ; on n'en lit que l'identifiant.
  clockSettings(attachment) {
    try {
      const sgid = attachment.getAttribute("sgid")
      const encoded = sgid.slice(0, sgid.lastIndexOf("--")).replace(/-/g, "+").replace(/_/g, "/")
      const payload = atob(encoded)
      const match = payload.match(/Figure\/horloge-(\d{2})?(\d{2})?(?:vide)?-(chiffres|nue)/)
      if (!match) return ["", true]
      const heure = match[1] ? `${parseInt(match[1], 10)}:${match[2]}` : ""
      return [heure, match[3] === "chiffres"]
    } catch {
      return ["", true]
    }
  }

  isClock(figure) {
    return !!figure?.querySelector(".rt-figure-img--horloge")
  }

  presentationOf(attachment, figure = null) {
    const element = figure || this.editorElement?.querySelector(`figure[data-trix-id="${attachment.id}"]`)
    try {
      return JSON.parse(element?.dataset.trixAttributes || "{}").presentation || null
    } catch {
      return null
    }
  }

  parse(presentation) {
    const match = /^taille-(\d+)(?: (gauche|centre|droite))?$/.exec(presentation || "")
    return match ? [match[1], match[2] || null] : [null, null]
  }

  get editorElement() {
    return this.element.querySelector("trix-editor")
  }
}
