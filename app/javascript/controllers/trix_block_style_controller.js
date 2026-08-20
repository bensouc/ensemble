import { Controller } from "@hotwired/stimulus"

// Menus de mise en forme du BLOC pour la toolbar Trix : alignement du texte,
// interligne. Un seul contrôleur, paramétré par la propriété CSS qu'il écrit.
//
// La valeur vit dans le `style` du bloc (cf. `plugins/trix-config.js`) : l'attribut
// de bloc pose l'enveloppe `<p>`, et sa valeur voyage dans les `htmlAttributes`.
// Trix n'a pas de bouton déclaratif pour ça — d'où ce contrôleur, qui applique les
// deux en une fois, comme `trix-palette` le fait pour les couleurs.
//
// La valeur « par défaut » de chaque menu (gauche, interligne normal) ne pose rien :
// on retire la déclaration. Un énoncé qui n'a jamais été mis en forme reste donc
// exactement ce qu'il était.
// On ne remplace QUE la déclaration concernée : alignement et interligne cohabitent
// dans le même `style`, et un bloc peut déjà porter l'autre.
function styleWith(style, property, value) {
  const declarations = String(style || "")
    .split(";")
    .map((declaration) => declaration.trim())
    .filter((declaration) => declaration && !declaration.toLowerCase().startsWith(`${property}:`))

  if (value) declarations.push(`${property}: ${value}`)

  return declarations.join("; ")
}

function valueFromStyle(style, property) {
  const match = new RegExp(`${property}\\s*:\\s*([^;]+)`, "i").exec(style || "")
  return match ? match[1].trim() : null
}

export default class extends Controller {
  static targets = ["panel", "preview", "trigger", "item"]
  // `property` : la propriété CSS écrite (text-align, line-height).
  // `default` : la valeur qui signifie « retirer la déclaration ».
  static values = { property: String, default: String }

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
    // Un seul popover ouvert à la fois dans la toolbar, nuanciers compris.
    this.element.closest("trix-toolbar")
      ?.querySelectorAll(".rt-tb__popover")
      .forEach((panel) => { panel.hidden = true })

    this.panelTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("pointerdown", this.onOutsidePointer, true)
    this.activeItem()?.focus() || this.itemTargets[0]?.focus()
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
      this.editorElement?.focus()
      return
    }

    const items = this.itemTargets
    const current = items.indexOf(document.activeElement)
    if (current === -1) return

    const step = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 }[event.key]
    if (step === undefined) return

    event.preventDefault()
    event.stopPropagation()
    items[(current + step + items.length) % items.length].focus()
  }

  // --- Application ----------------------------------------------------------

  pick(event) {
    event.preventDefault()
    this.apply(event.currentTarget.dataset.value)
  }

  apply(value) {
    const editor = this.withRestoredSelection()
    if (!editor) return

    this.recordFormattingUndoEntry(editor)

    // « Gauche » retire l'enveloppe et repose la valeur par défaut : un titre garde
    // son <h1>, on n'y écrit que `align="left"`.
    // La valeur par défaut retire l'enveloppe : un paragraphe sans mise en forme
    // reste un paragraphe ordinaire.
    if (value === this.defaultValue && !this.otherPropertySet(editor)) {
      while (editor.attributeIsActive("blockStyle")) editor.deactivateAttribute("blockStyle")
    }

    this.eachSelectedBlock(editor, (index, position) => {
      const block = editor.getDocument().getBlockAtIndex(index)
      // Un titre porte le style sur sa propre balise ; un paragraphe a besoin de
      // l'enveloppe <p>. Réactiver l'attribut sur un bloc qui le porte déjà
      // l'empilerait — mesuré : <p><p>texte</p></p>.
      if (value !== this.defaultValue && !this.acceptsStyle(block) && !editor.attributeIsActive("blockStyle")) {
        editor.activateAttribute("blockStyle")
      }
      this.setAlignment(editor, position, value)
    })

    this.setPreview(value)
    this.hide()
  }

  // La valeur s'applique bloc par bloc : le setter de Trix ne connaît qu'une
  // position. On parcourt donc les blocs couverts par la sélection.
  eachSelectedBlock(editor, callback) {
    const document = editor.getDocument()
    const range = editor.getSelectedRange() || [editor.getPosition(), editor.getPosition()]
    const first = document.locationFromPosition(range[0]).index
    const last = document.locationFromPosition(range[1]).index

    for (let index = first; index <= last; index++) {
      callback(index, editor.getDocument().positionFromLocation({ index, offset: 0 }))
    }
  }

  setAlignment(editor, position, value) {
    const composition = editor.composition
    // Trix 2.1 orthographie la méthode « Atribute » ; on accepte les deux pour ne
    // pas casser silencieusement à la prochaine mise à jour.
    const setter = composition?.setHTMLAtributeAtPosition || composition?.setHTMLAttributeAtPosition
    if (!setter) return

    const index = editor.getDocument().locationFromPosition(position).index
    const current = editor.getDocument().getBlockAtIndex(index)?.htmlAttributes?.style
    const written = value === this.defaultValue ? null : value
    setter.call(composition, position, "style", styleWith(current, this.propertyValue, written))
  }

  acceptsStyle(block) {
    const last = block?.getLastAttribute?.()
    return !!last && !!window.Trix?.config?.blockAttributes?.[last]?.htmlAttributes?.includes("style")
  }

  // Même raison que dans `trix-palette` : `activateAttribute` court-circuite
  // l'enregistrement de l'historique que Trix fait pour ses propres boutons.
  recordFormattingUndoEntry(editor) {
    editor.recordUndoEntry("Alignment", { consolidatable: false })
  }

  // Cliquer dans la toolbar sort le focus de l'éditeur : on relit la sélection
  // conservée par Trix, on redonne le focus, puis on la restaure.
  withRestoredSelection() {
    const element = this.editorElement
    const editor = element?.editor
    if (!editor) return null

    const range = editor.getSelectedRange()
    element.focus()
    if (range) editor.setSelectedRange(range)
    return editor
  }

  // --- Aperçu ---------------------------------------------------------------

  syncPreview() {
    this.setPreview(this.currentValue())
  }

  // L'icône du déclencheur est celle de l'option active : pas de duplication de
  // SVG en JS, on recopie celui du menu.
  setPreview(value) {
    const active = value || this.defaultValue

    this.itemTargets.forEach((item) => {
      const isActive = item.dataset.value === active
      item.setAttribute("aria-checked", isActive ? "true" : "false")
      item.classList.toggle("rt-tb__menu-item--active", isActive)
      if (isActive && this.hasPreviewTarget) {
        this.previewTarget.innerHTML = item.querySelector("svg")?.outerHTML || ""
      }
    })
  }

  currentValue() {
    try {
      const editor = this.editorElement?.editor
      if (!editor) return this.defaultValue

      const document = editor.getDocument()
      const index = document.locationFromPosition(editor.getPosition()).index
      const style = document.getBlockAtIndex(index)?.htmlAttributes?.style
      return valueFromStyle(style, this.propertyValue) || this.defaultValue
    } catch {
      return this.defaultValue
    }
  }

  // Retirer l'enveloppe alors que l'autre menu y a écrit effacerait sa mise en
  // forme : on ne la retire que si le bloc ne porte plus que notre propriété.
  otherPropertySet(editor) {
    try {
      const document = editor.getDocument()
      const index = document.locationFromPosition(editor.getPosition()).index
      const style = styleWith(
        document.getBlockAtIndex(index)?.htmlAttributes?.style,
        this.propertyValue,
        null
      )
      return style.trim().length > 0
    } catch {
      return true
    }
  }

  // --- Accès à l'éditeur ----------------------------------------------------

  get editorElement() {
    const toolbar = this.element.closest("trix-toolbar")
    if (!toolbar) return null

    if (toolbar.editorElement) return toolbar.editorElement

    const sibling = toolbar.nextElementSibling
    return sibling && sibling.matches("trix-editor") ? sibling : null
  }

  get isOpen() {
    return this.hasPanelTarget && !this.panelTarget.hidden
  }

  activeItem() {
    return this.itemTargets.find((item) => item.getAttribute("aria-checked") === "true")
  }
}
