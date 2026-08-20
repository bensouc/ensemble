import { Controller } from "@hotwired/stimulus"

// Nuancier de couleurs pour la toolbar Trix (couleur du texte / surlignage).
//
// Remplace l'ancien couple `dropdown` + `color-picker` (@jaames/iro) : un roue
// chromatique de 280px pour choisir « rouge » était à la fois lent à charger
// (~45 ko) et lent à utiliser. Ici : 8 pastilles de la palette de l'app en un
// clic, plus <input type="color"> natif pour les cas particuliers.
//
// Le contrôleur retrouve son éditeur tout seul via l'attribut `toolbar` que
// Trix pose sur <trix-editor>, il n'a donc pas besoin d'un contrôleur parent.
export default class extends Controller {
  static targets = ["panel", "preview", "trigger"]
  static values = { attribute: String }

  connect() {
    this.onOutsidePointer = this.onOutsidePointer.bind(this)
    this.syncPreview = this.syncPreview.bind(this)

    this.editorElement?.addEventListener("trix-selection-change", this.syncPreview)
    this.syncPreview()
  }

  disconnect() {
    this.editorElement?.removeEventListener("trix-selection-change", this.syncPreview)
    document.removeEventListener("pointerdown", this.onOutsidePointer, true)
  }

  // --- Ouverture / fermeture ------------------------------------------------

  toggle(event) {
    event.preventDefault()
    this.isOpen ? this.hide() : this.show()
  }

  show() {
    // Un seul popover ouvert à la fois dans la toolbar — nuanciers et menu
    // d'alignement compris, sinon deux popovers se chevauchent.
    this.element.closest("trix-toolbar")
      ?.querySelectorAll(".rt-tb__popover")
      .forEach((panel) => { panel.hidden = true })

    this.panelTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    // Écouteur global posé seulement pendant l'ouverture (et retiré ensuite) :
    // pas de listener document permanent.
    document.addEventListener("pointerdown", this.onOutsidePointer, true)
    this.chips[0]?.focus()
  }

  hide() {
    this.panelTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("pointerdown", this.onOutsidePointer, true)
  }

  onOutsidePointer(event) {
    if (!this.element.contains(event.target)) this.hide()
  }

  keydown(event) {
    if (!this.isOpen) return

    if (event.key === "Escape") {
      event.stopPropagation()
      this.hide()
      this.focusEditor()
      return
    }

    const chips = this.chips
    const current = chips.indexOf(document.activeElement)
    if (current === -1) return

    const step = { ArrowRight: 1, ArrowDown: 4, ArrowLeft: -1, ArrowUp: -4 }[event.key]
    if (step === undefined) return

    event.preventDefault()
    event.stopPropagation()
    const next = (current + step + chips.length) % chips.length
    chips[next].focus()
  }

  // --- Application ----------------------------------------------------------

  pick(event) {
    event.preventDefault()
    this.apply(event.currentTarget.dataset.color)
  }

  pickCustom(event) {
    // `input` se déclenche à chaque mouvement dans le sélecteur natif :
    // on garde le popover ouvert pour laisser l'aperçu vivant.
    this.apply(event.currentTarget.value, { keepOpen: true })
  }

  clear(event) {
    event.preventDefault()
    const editor = this.withRestoredSelection()
    if (!editor) return

    this.recordFormattingUndoEntry(editor)
    editor.deactivateAttribute(this.attributeValue)
    this.setPreview(null)
    this.hide()
  }

  apply(color, { keepOpen = false } = {}) {
    const editor = this.withRestoredSelection()
    if (!editor) return

    this.recordFormattingUndoEntry(editor)
    editor.activateAttribute(this.attributeValue, color)
    this.setPreview(color)
    if (!keepOpen) this.hide()
  }

  // Trix n'enregistre l'historique que dans EditorController, sur le chemin de
  // ses propres boutons :
  //
  //   toolbarDidUpdateAttribute(name, value) {
  //     this.recordFormattingUndoEntry(name)   // <- l'entrée d'annulation
  //     this.composition.setCurrentAttribute(name, value)
  //     ...
  //
  // `editor.activateAttribute()` appelle directement `setCurrentAttribute` et
  // court-circuite donc cette étape : sans ce qui suit, un changement de couleur
  // n'est ni annulable ni rétablissable.
  //
  // On reproduit la condition de Trix (`recordFormattingUndoEntry`) : rien à
  // enregistrer si la sélection est vide, l'attribut est alors seulement mis en
  // attente pour la frappe suivante.
  //
  // Trix passe `consolidatable: true` avec un contexte de position/temps calculé
  // par EditorController, hors de portée d'ici. On prend `false` : chaque
  // changement de couleur devient une entrée distincte, ce qui évite de fusionner
  // à tort deux mises en couleur sur des sélections différentes.
  recordFormattingUndoEntry(editor) {
    const range = editor.getSelectedRange()
    if (!range || range[0] === range[1]) return

    editor.recordUndoEntry("Formatting", { consolidatable: false })
  }

  // Cliquer dans la toolbar peut sortir le focus de l'éditeur. Trix conserve sa
  // propre sélection, donc on la relit, on redonne le focus, puis on la
  // restaure : l'attribut s'applique bien à la sélection d'origine (ou reste en
  // attente pour la frappe suivante si le curseur est simplement posé).
  withRestoredSelection() {
    const element = this.editorElement
    const editor = element?.editor
    if (!editor) return null

    const range = editor.getSelectedRange()
    element.focus()
    if (range) editor.setSelectedRange(range)
    return editor
  }

  focusEditor() {
    this.editorElement?.focus()
  }

  // --- Aperçu ---------------------------------------------------------------

  syncPreview() {
    this.setPreview(this.currentColor())
  }

  setPreview(color) {
    if (!this.hasPreviewTarget) return
    this.previewTarget.style.setProperty("--rt-swatch", color || "transparent")
    this.previewTarget.classList.toggle("rt-tb__swatch--empty", !color)
  }

  currentColor() {
    try {
      return this.editorElement?.editor?.composition?.currentAttributes?.[this.attributeValue] || null
    } catch {
      return null
    }
  }

  // --- Accès à l'éditeur ----------------------------------------------------

  get editorElement() {
    const toolbar = this.element.closest("trix-toolbar")
    if (!toolbar) return null

    // API officielle depuis Trix 2.1.16 : <trix-toolbar> résout lui-même
    // l'éditeur associé via l'attribut [toolbar].
    if (toolbar.editorElement) return toolbar.editorElement

    // Secours : Trix insère la toolbar juste avant son éditeur.
    const sibling = toolbar.nextElementSibling
    return sibling && sibling.matches("trix-editor") ? sibling : null
  }

  get isOpen() {
    return this.hasPanelTarget && !this.panelTarget.hidden
  }

  get chips() {
    return Array.from(this.panelTarget.querySelectorAll(".rt-tb__chip"))
  }
}
