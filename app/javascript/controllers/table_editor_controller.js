import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from "@rails/request.js"

// Éditeur de tableaux ActionText.
//
// Posé sur le champ (hors pièce jointe), pas à l'intérieur du tableau : le
// balisage d'une pièce jointe traverse le sanitizer de Trix, qui supprime
// `data-controller` et `data-action`. Tout passe donc par de la délégation
// par classe, mais **scopée à this.element** — l'ancienne version posait six
// écouteurs `document` en phase de capture (click, mousedown, keydown, keyup,
// keypress, blur), actifs sur chaque clic de l'application entière.
//
// La capture sur le champ suffit : elle s'exécute avant que l'événement
// n'atteigne <trix-editor>, ce qui permet de soustraire à Trix ce qui se passe
// dans une cellule sans jamais toucher au document.
//
// Persistance : l'ancienne version envoyait une requête par cellule quittée et
// remplaçait l'innerHTML du tableau avec la réponse, ce qui faisait perdre le
// focus en pleine saisie. Ici toutes les opérations sont locales et immédiates,
// l'état complet est envoyé en une requête groupée (debounce), et la réponse ne
// touche jamais au DOM.
const STYLE_FLAGS = ["b", "i", "u"]
const ALIGNMENTS = ["left", "center", "right"]
const SAVE_DELAY = 600
const TOOLBAR_INACTIVE_HINT =
  "Indisponible pendant l'édition d'un tableau — la mise en forme se fait dans la barre du tableau"
const MAX_ROWS = 60
const MAX_COLUMNS = 20

// Le DOM restitue toujours une couleur en `rgb(...)`, alors que le modèle
// n'accepte que les teintes de sa liste blanche, en hexadécimal.
function toHex(value) {
  const parts = String(value).match(/^rgba?\((\d+),\s*(\d+),\s*(\d+)/)
  if (!parts) return null

  return `#${parts.slice(1, 4).map((n) => Number(n).toString(16).padStart(2, "0")).join("").toUpperCase()}`
}

export default class extends Controller {
  connect() {
    this.pending = new Map() // racine de tableau -> timer
    this.inFlight = new Set()
    this.activeCell = null
    this.resubmitting = false

    this.hydrate = this.hydrate.bind(this)
    this.onMousedown = this.onMousedown.bind(this)
    this.onClick = this.onClick.bind(this)
    this.onKeydown = this.onKeydown.bind(this)
    this.onInput = this.onInput.bind(this)
    this.onPaste = this.onPaste.bind(this)
    this.onFocusIn = this.onFocusIn.bind(this)
    this.onFocusOut = this.onFocusOut.bind(this)
    this.onSubmit = this.onSubmit.bind(this)

    // Trix retire `contenteditable` du balisage des pièces jointes. On le
    // repose à l'initialisation et à l'insertion d'un tableau — mais surtout
    // pas sur `trix-render`, qui rendrait la boucle décrite plus bas.
    this.element.addEventListener("trix-initialize", this.hydrate)
    this.element.addEventListener("trix-attachment-add", this.hydrate)

    this.element.addEventListener("mousedown", this.onMousedown, true)
    this.element.addEventListener("click", this.onClick, true)
    this.element.addEventListener("keydown", this.onKeydown, true)
    this.element.addEventListener("input", this.onInput, true)
    this.element.addEventListener("paste", this.onPaste, true)
    this.element.addEventListener("focusin", this.onFocusIn, true)
    this.element.addEventListener("focusout", this.onFocusOut, true)

    this.form = this.element.closest("form")
    this.form?.addEventListener("submit", this.onSubmit, true)

    // Pas de MutationObserver ici, et pas d'hydratation sur `trix-render` :
    // poser `contenteditable` est une mutation que l'observateur interne de
    // Trix voit, ce qui déclenche un re-rendu, qui remplace le balisage de la
    // pièce jointe (donc sans `contenteditable`), qui déclenche une nouvelle
    // hydratation… La boucle fige le navigateur.
    //
    // L'éditabilité est donc posée paresseusement, au moment où elle sert :
    // au mousedown sur une cellule et avant un déplacement au clavier. Les
    // deux passes ci-dessous ne servent qu'à l'affordance visuelle et sont
    // bornées.
    requestAnimationFrame(() => this.hydrate())
    this.hydrate()
  }

  disconnect() {
    this.pending.forEach((timer) => clearTimeout(timer))
    this.pending.clear()

    this.element.removeEventListener("trix-initialize", this.hydrate)
    this.element.removeEventListener("trix-attachment-add", this.hydrate)
    this.element.removeEventListener("mousedown", this.onMousedown, true)
    this.element.removeEventListener("click", this.onClick, true)
    this.element.removeEventListener("keydown", this.onKeydown, true)
    this.element.removeEventListener("input", this.onInput, true)
    this.element.removeEventListener("paste", this.onPaste, true)
    this.element.removeEventListener("focusin", this.onFocusIn, true)
    this.element.removeEventListener("focusout", this.onFocusOut, true)
    this.form?.removeEventListener("submit", this.onSubmit, true)
  }

  // --- Hydratation ---------------------------------------------------------

  hydrate() {
    this.element
      .querySelectorAll(".rt-table--editor .rt-cell:not([contenteditable]), .table-editor td:not([contenteditable])")
      .forEach((cell) => cell.setAttribute("contenteditable", "true"))
  }

  // --- Écouteurs -----------------------------------------------------------

  onMousedown(event) {
    // Le mousedown sur un bouton de la toolbar doit être neutralisé ET soustrait
    // à Trix. `preventDefault` seul ne suffit pas : l'événement poursuivait sa
    // route jusqu'à <trix-editor>, qui refocalise de son côté. Le focus quittait
    // alors la cellule, Trix re-rendait la pièce jointe, et le bouton était
    // remplacé entre le mousedown et le mouseup — si bien que le navigateur ne
    // dispatchait aucun `click` : le bouton semblait simplement inerte.
    if (this.buttonFor(event.target)) {
      event.preventDefault()
      event.stopPropagation()
      return
    }

    const cell = this.cellFor(event.target)
    if (!cell) return

    // Cliquer dans une pièce jointe amène Trix à la SÉLECTIONNER en bloc au
    // lieu d'y poser un caret : sans cette interception, les cellules ne sont
    // pas éditables. On soustrait l'événement à Trix (l'écouteur de
    // <trix-editor> est en aval de cette capture) et on rend la cellule
    // éditable avant que le navigateur ne calcule la position du caret —
    // ce qui laisse le clic positionner le curseur normalement, au lieu de le
    // forcer en fin de cellule.
    event.stopPropagation()
    cell.setAttribute("contenteditable", "true")
  }

  onClick(event) {
    const button = this.buttonFor(event.target)

    if (button) {
      // Le sanitizer de Trix retire `type="button"` : sans ça, un clic sur la
      // toolbar soumettrait le formulaire.
      event.preventDefault()
      event.stopPropagation()

      const sgid = this.sgidFor(button.closest(".rt-table--editor, .table-editor"))
      const root = this.liveRootFor(sgid)
      if (root) this.runAction(root, sgid, button)
      return
    }

    // Clic dans une cellule : on le soustrait à Trix, sans preventDefault pour
    // que le navigateur place le caret là où l'utilisateur a cliqué.
    if (this.cellFor(event.target)) event.stopPropagation()
  }

  onKeydown(event) {
    const cell = this.cellFor(event.target)
    if (!cell) return

    // Soustrait la frappe à Trix (l'écouteur de <trix-editor> est en aval),
    // sans empêcher l'action par défaut : la saisie dans la cellule fonctionne.
    event.stopPropagation()

    const root = cell.closest(".rt-table--editor, .table-editor")

    switch (event.key) {
      case "Tab":
        event.preventDefault()
        this.moveFocus(cell, event.shiftKey ? -1 : 1, 0)
        return
      case "Enter":
        event.preventDefault()
        this.moveFocus(cell, 0, event.shiftKey ? -1 : 1)
        return
      case "ArrowUp":
        event.preventDefault()
        this.moveFocus(cell, 0, -1)
        return
      case "ArrowDown":
        event.preventDefault()
        this.moveFocus(cell, 0, 1)
        return
      case "Escape":
        event.preventDefault()
        this.element.querySelector("trix-editor")?.focus()
        return
      case "Backspace":
      case "Delete":
        // Cellule déjà vide : rien à supprimer, et on évite que le navigateur
        // n'aille mordre sur le balisage du tableau.
        if (!cell.textContent.trim()) event.preventDefault()
        return
      default:
        if ((event.metaKey || event.ctrlKey) && root) {
          const flag = { b: "b", i: "i", u: "u" }[event.key.toLowerCase()]
          if (flag) {
            event.preventDefault()
            cell.classList.toggle(`rt-c-${flag}`)
            this.scheduleSave(this.sgidFor(root), { immediate: true })
          }
        }
    }
  }

  onInput(event) {
    const cell = this.cellFor(event.target)
    if (!cell) return

    event.stopPropagation()
    this.scheduleSave(this.sgidFor(cell.closest(".rt-table--editor, .table-editor")))
  }

  onPaste(event) {
    const cell = this.cellFor(event.target)
    if (!cell) return

    event.stopPropagation()
    const text = event.clipboardData?.getData("text/plain")
    if (!text) return

    const grid = text.replace(/\r\n?/g, "\n").replace(/\n$/, "").split("\n").map((line) => line.split("\t"))
    const isGrid = grid.length > 1 || grid.some((line) => line.length > 1)

    event.preventDefault()

    const root = cell.closest(".rt-table--editor, .table-editor")
    if (!root) return

    if (isGrid) {
      // Collage depuis un tableur : on remplit la grille à partir de la
      // cellule courante, en l'agrandissant si nécessaire.
      this.fillFrom(root, cell, grid)
    } else {
      // Collage simple : texte brut, sans le balisage de la source.
      cell.textContent = text
      this.placeCaretAtEnd(cell)
    }

    this.scheduleSave(this.sgidFor(root), { immediate: true })
  }

  // On mémorise une POSITION, pas un nœud : Trix remplace le balisage de la
  // pièce jointe à divers moments (prise de focus, re-rendu), et une référence
  // d'élément devient alors silencieusement obsolète — la cellule mémorisée
  // n'est plus dans le document, et les actions qui en dépendent ne font rien.
  onFocusIn(event) {
    const cell = this.cellFor(event.target)
    if (!cell) return

    const root = cell.closest(".rt-table--editor, .table-editor")
    const position = this.positionOf(cell)
    this.activeCell = root && position ? { sgid: this.sgidFor(root), ...position } : null

    this.setMainToolbarInactive(true)
  }

  onFocusOut(event) {
    const cell = this.cellFor(event.target)
    if (!cell) return

    const root = cell.closest(".rt-table--editor, .table-editor")
    if (!root) return

    // Le focus reste-t-il dans ce tableau ? Si oui on enregistre, mais sans
    // resynchroniser l'instantané : cela re-rendrait la pièce jointe et
    // volerait le focus à la cellule qui vient de le recevoir.
    const staysInside = event.relatedTarget && root.contains(event.relatedTarget)
    this.scheduleSave(this.sgidFor(root), { immediate: true, syncSnapshot: !staysInside })

    if (!staysInside) this.setMainToolbarInactive(false)
  }

  // La toolbar principale agit sur le document Trix, jamais sur le contenu
  // d'une cellule : celui-ci vit dans une pièce jointe, hors du document. Tant
  // qu'une cellule a le focus, la neutraliser évite de laisser croire que
  // « gras » ou « titre » s'y appliqueraient. La bascule est purement visuelle
  // (classe + pointer-events) plutôt qu'un `disabled` sur les boutons, que
  // Trix repose lui-même à chaque changement de sélection.
  //
  // Le clavier est déjà correctement routé : ⌘B/⌘I/⌘U dans une cellule sont
  // interceptés par onKeydown et appliquent le style de cellule.
  setMainToolbarInactive(inactive) {
    const toolbar = this.element.querySelector("trix-toolbar")
    if (!toolbar) return

    toolbar.classList.toggle("rt-tb--table-focus", inactive)

    // Infobulle native, cohérente avec les boutons de la toolbar. Les groupes
    // étant en `pointer-events: none`, le survol atteint la rangée elle-même,
    // qui porte donc le `title`.
    const row = toolbar.querySelector(".trix-button-row")
    if (!row) return

    if (inactive) {
      row.setAttribute("title", TOOLBAR_INACTIVE_HINT)
      row.setAttribute("aria-disabled", "true")
    } else {
      row.removeAttribute("title")
      row.removeAttribute("aria-disabled")
    }
  }

  // Le contenu des cellules vit dans l'enregistrement Table, pas dans le corps
  // du rich text : il doit être écrit avant que le formulaire ne parte.
  onSubmit(event) {
    if (this.resubmitting || (!this.pending.size && !this.inFlight.size)) return

    event.preventDefault()
    event.stopPropagation()

    const submitter = event.submitter
    this.flushAll().then(() => {
      this.resubmitting = true
      this.form.requestSubmit(submitter)
    })
  }

  // --- Actions de la toolbar -----------------------------------------------

  runAction(root, sgid, button) {
    const table = root.querySelector("table")
    if (!table) return

    const position = this.activePositionIn(root)
    const cell = this.activeCellIn(root)
    const { row, col } = position ?? { row: null, col: null }

    const classes = button.classList
    if (classes.contains("rt-t-row-before")) this.insertRow(table, row ?? table.rows.length, { before: true })
    else if (classes.contains("rt-t-row-after")) this.insertRow(table, row ?? table.rows.length - 1, { before: false })
    else if (classes.contains("rt-t-row-delete")) this.deleteRow(table, row ?? table.rows.length - 1)
    else if (classes.contains("rt-t-col-before")) this.insertColumn(table, col ?? this.columnCount(table), { before: true })
    else if (classes.contains("rt-t-col-after")) this.insertColumn(table, col ?? this.columnCount(table) - 1, { before: false })
    else if (classes.contains("rt-t-col-delete")) this.deleteColumn(table, col ?? this.columnCount(table) - 1)
    else if (classes.contains("rt-t-header")) this.toggleHeader(root, table, button)
    else if (classes.contains("rt-t-align-left")) this.alignColumn(table, col, "left")
    else if (classes.contains("rt-t-align-center")) this.alignColumn(table, col, "center")
    else if (classes.contains("rt-t-align-right")) this.alignColumn(table, col, "right")
    // La couleur du texte est portée par un `style` inline, seul canal libre
    // dans une pièce jointe. La teinte est relue sur la pastille elle-même,
    // faute de pouvoir la transporter par un `data-*` (retiré par le sanitizer).
    else if (classes.contains("rt-t-color-clear")) {
      if (cell) cell.style.color = ""
      else return
    }
    else if (classes.contains("rt-t-color")) {
      if (cell) cell.style.color = getComputedStyle(button).backgroundColor
      else return
    }
    else {
      const flag = STYLE_FLAGS.find((f) => classes.contains(`rt-t-style-${f}`))
      if (flag && cell) cell.classList.toggle(`rt-c-${flag}`)
      else return
    }

    this.hydrate()

    // Rendre le focus à la cellule courante. Plusieurs actions reconstruisent
    // des cellules — basculer l'en-tête re-crée les éléments, une balise ne se
    // renommant pas — et le focus se perdrait. Or le bloc « Cellule » de la
    // barre s'affiche sur `:focus-within` : sans ça, il disparaîtrait au
    // premier changement de structure, et l'utilisateur perdrait sa place.
    const restored = this.activeCellIn(root)
    if (restored) {
      restored.focus()
      this.placeCaretAtEnd(restored)
    }

    this.scheduleSave(sgid, { immediate: true })
  }

  insertRow(table, index, { before }) {
    if (table.rows.length >= MAX_ROWS) return

    let at = before ? index : index + 1
    // L'en-tête reste la première ligne.
    if (this.hasHeader(table) && at === 0) at = 1
    at = Math.max(0, Math.min(at, table.rows.length))

    const columns = this.columnCount(table)
    const tr = table.insertRow(at)
    for (let c = 0; c < columns; c++) {
      tr.appendChild(this.buildCell("td", this.alignOfColumn(table, c)))
    }
    this.applyHeader(table, this.hasHeader(table))
  }

  deleteRow(table, index) {
    if (table.rows.length <= 1) return
    if (index == null || index < 0 || index >= table.rows.length) return

    table.deleteRow(index)
    this.applyHeader(table, this.hasHeader(table))
  }

  insertColumn(table, index, { before }) {
    const columns = this.columnCount(table)
    if (columns >= MAX_COLUMNS) return

    const at = Math.max(0, Math.min(before ? index : index + 1, columns))
    Array.from(table.rows).forEach((tr, r) => {
      const isHeader = this.hasHeader(table) && r === 0
      const cell = this.buildCell(isHeader ? "th" : "td", this.alignOfColumn(table, Math.min(at, columns - 1)))
      tr.insertBefore(cell, tr.cells[at] ?? null)
    })
  }

  deleteColumn(table, index) {
    const columns = this.columnCount(table)
    if (columns <= 1) return
    if (index == null || index < 0 || index >= columns) return

    Array.from(table.rows).forEach((tr) => tr.cells[index]?.remove())
  }

  toggleHeader(root, table, button) {
    const next = !this.hasHeader(table)
    this.applyHeader(table, next)
    button.classList.toggle("rt-is-on", next)
  }

  applyHeader(table, enabled) {
    Array.from(table.rows).forEach((tr, r) => {
      const wanted = enabled && r === 0 ? "TH" : "TD"
      Array.from(tr.cells).forEach((cell) => {
        if (cell.tagName !== wanted) this.retag(cell, wanted.toLowerCase())
      })
    })
  }

  // Sans cellule active, l'alignement s'applique à tout le tableau plutôt que
  // de ne rien faire en silence.
  alignColumn(table, col, alignment) {
    Array.from(table.rows).forEach((tr) => {
      const cells = col == null ? Array.from(tr.cells) : [tr.cells[col]]
      cells.forEach((cell) => {
        if (!cell) return
        ALIGNMENTS.forEach((a) => cell.classList.remove(`rt-al-${a}`))
        if (alignment !== "left") cell.classList.add(`rt-al-${alignment}`)
      })
    })
  }

  // --- Manipulation de grille ----------------------------------------------

  buildCell(tagName, alignment) {
    const cell = document.createElement(tagName)
    cell.className = `rt-cell table-cell${alignment && alignment !== "left" ? ` rt-al-${alignment}` : ""}`
    cell.setAttribute("contenteditable", "true")
    return cell
  }

  // Une balise ne se renomme pas : on reconstruit l'élément en conservant
  // classes et contenu.
  retag(cell, tagName) {
    const replacement = document.createElement(tagName)
    replacement.className = cell.className
    replacement.innerHTML = cell.innerHTML
    replacement.setAttribute("contenteditable", "true")
    cell.replaceWith(replacement)
    return replacement
  }

  fillFrom(root, cell, grid) {
    const table = root.querySelector("table")
    const origin = this.positionOf(cell)
    if (!origin) return

    const neededRows = Math.min(origin.row + grid.length, MAX_ROWS)
    const neededCols = Math.min(origin.col + Math.max(...grid.map((line) => line.length)), MAX_COLUMNS)

    while (table.rows.length < neededRows) this.insertRow(table, table.rows.length - 1, { before: false })
    while (this.columnCount(table) < neededCols) this.insertColumn(table, this.columnCount(table) - 1, { before: false })

    grid.forEach((line, r) => {
      line.forEach((value, c) => {
        const target = table.rows[origin.row + r]?.cells[origin.col + c]
        if (target) target.textContent = value.trim()
      })
    })
  }

  moveFocus(cell, deltaCol, deltaRow) {
    const table = cell.closest("table")
    const position = this.positionOf(cell)
    if (!table || !position) return

    let { row, col } = position
    col += deltaCol
    row += deltaRow

    const columns = this.columnCount(table)
    if (col >= columns) { col = 0; row += 1 }
    if (col < 0) { col = columns - 1; row -= 1 }
    if (row < 0 || row >= table.rows.length) return

    const target = table.rows[row]?.cells[col]
    if (target) {
      // Une cellule non éditable n'est pas focusable : l'éditabilité étant
      // posée paresseusement, on l'assure ici avant de déplacer le focus.
      target.setAttribute("contenteditable", "true")
      target.focus()
      this.placeCaretAtEnd(target)
    }
  }

  placeCaretAtEnd(cell) {
    const range = document.createRange()
    range.selectNodeContents(cell)
    range.collapse(false)
    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
  }

  // --- Persistance ---------------------------------------------------------

  scheduleSave(sgid, { immediate = false, syncSnapshot = false } = {}) {
    if (!sgid) return

    clearTimeout(this.pending.get(sgid))

    if (immediate) {
      this.pending.delete(sgid)
      this.save(sgid, { syncSnapshot })
      return
    }

    this.pending.set(sgid, setTimeout(() => {
      this.pending.delete(sgid)
      this.save(sgid)
    }, SAVE_DELAY))
  }

  async flushAll() {
    const sgids = new Set(this.pending.keys())
    sgids.forEach((sgid) => clearTimeout(this.pending.get(sgid)))
    this.pending.clear()

    // Avant envoi du formulaire, le focus n'a plus d'importance : on
    // resynchronise l'instantané de chaque tableau.
    await Promise.all([...sgids].map((sgid) => this.save(sgid, { syncSnapshot: true })))
    // Les enregistrements déjà partis doivent aussi être terminés.
    await Promise.all([...this.inFlight])
  }

  // La réponse ne remplace JAMAIS le DOM en cours d'édition : c'est ce qui
  // faisait perdre le focus en pleine saisie.
  //
  // Elle sert en revanche à resynchroniser l'instantané `content` de la pièce
  // jointe, car Trix reconstruit celle-ci à partir de cet instantané dès que son
  // cache de vues est invalidé — sans quoi une colonne ajoutée dans le DOM
  // réapparaîtrait absente au premier re-rendu. La resynchronisation n'a lieu
  // qu'aux moments où le focus n'est plus dans le tableau (`syncSnapshot`),
  // puisque `setAttributes` déclenche justement ce re-rendu.
  async save(sgid, { syncSnapshot = false } = {}) {
    // Toujours relire le DOM vivant : un root capturé plus tôt peut avoir été
    // détaché par un re-rendu, et on enregistrerait alors un état périmé.
    const root = this.liveRootFor(sgid)
    if (!root) return

    const request = new FetchRequest("patch", `/tables/${encodeURIComponent(sgid)}`, {
      contentType: "application/json",
      responseKind: "json",
      body: JSON.stringify({ method: "replace", table: this.readState(root) })
    })

    const promise = request
      .perform()
      .then(async (response) => {
        if (!response.ok) return
        const payload = await response.json
        if (syncSnapshot && payload?.content) this.syncSnapshot(sgid, payload.content)
      })
      .catch((error) => {
        console.error("Enregistrement du tableau impossible", error)
      })

    this.inFlight.add(promise)
    await promise
    this.inFlight.delete(promise)
  }

  syncSnapshot(sgid, content) {
    const editor = this.element.querySelector("trix-editor")
    const attachment = editor?.editor?.getDocument().getAttachments()
      .find((candidate) => candidate.getAttribute("sgid") === sgid)

    if (attachment && attachment.getAttribute("content") !== content) {
      attachment.setAttributes({ content })
      // Le re-rendu repose un balisage neuf, donc sans `contenteditable`.
      this.hydrate()
    }
  }

  readState(root) {
    const table = root.querySelector("table")
    const rows = Array.from(table?.rows ?? [])
    const data = {}
    const cellStyles = {}
    const cellColors = {}
    let columns = 0

    rows.forEach((tr, r) => {
      const cells = Array.from(tr.cells)
      columns = Math.max(columns, cells.length)

      cells.forEach((cell, c) => {
        // Le navigateur insère des espaces insécables dans une zone
        // contenteditable : on les normalise avant comparaison.
        const text = cell.textContent.replace(/\u00a0/g, " ").trim()
        if (text) data[`${r}-${c}`] = text

        const flags = STYLE_FLAGS.filter((flag) => cell.classList.contains(`rt-c-${flag}`))
        if (flags.length) cellStyles[`${r}-${c}`] = flags

        const color = toHex(cell.style.color)
        if (color) cellColors[`${r}-${c}`] = color
      })
    })

    const colAligns = []
    for (let c = 0; c < columns; c++) colAligns[c] = this.alignOfColumn(table, c)

    return {
      rows: rows.length,
      columns,
      header_row: this.hasHeader(table),
      data,
      cell_styles: cellStyles,
      cell_colors: cellColors,
      col_aligns: colAligns
    }
  }

  // --- Utilitaires ---------------------------------------------------------

  // Trix remplace le balisage d'une pièce jointe à divers moments (changement
  // de focus, re-rendu). Le nœud porté par un événement peut donc appartenir à
  // un arbre déjà détaché : agir dessus n'a aucun effet visible. Toute
  // opération repart donc du sgid — la seule identité stable — et re-résout le
  // DOM vivant, `this.element` étant par construction dans le document.
  liveRootFor(sgid) {
    if (!sgid) return null

    for (const figure of this.element.querySelectorAll("figure[data-trix-attachment]")) {
      let candidate = null
      try {
        candidate = JSON.parse(figure.getAttribute("data-trix-attachment")).sgid
      } catch {
        continue
      }
      if (candidate === sgid) return figure.querySelector(".rt-table--editor, .table-editor")
    }
    return null
  }

  // `id` ne survit pas au sanitizer de Trix : le sgid est relu depuis le JSON
  // que Trix pose sur le <figure> de la pièce jointe.
  sgidFor(root) {
    const figure = root.closest("figure[data-trix-attachment]")
    if (!figure) return null

    try {
      return JSON.parse(figure.getAttribute("data-trix-attachment")).sgid || null
    } catch {
      return null
    }
  }

  cellFor(node) {
    const element = node instanceof Element ? node : node?.parentElement
    const cell = element?.closest(".rt-cell, .table-cell, .table-editor td, .table-editor th")
    return cell && this.element.contains(cell) ? cell : null
  }

  buttonFor(node) {
    const element = node instanceof Element ? node : node?.parentElement
    const button = element?.closest(".rt-table__toolbar button, .table-toolbar button")
    return button && this.element.contains(button) ? button : null
  }

  // Résout la position mémorisée sur le DOM vivant du tableau concerné.
  activePositionIn(root) {
    if (!this.activeCell) return null
    return this.sgidFor(root) === this.activeCell.sgid ? this.activeCell : null
  }

  activeCellIn(root) {
    const position = this.activePositionIn(root)
    if (!position) return null

    return root.querySelector("table")?.rows[position.row]?.cells[position.col] ?? null
  }

  positionOf(cell) {
    if (!cell) return null

    const tr = cell.closest("tr")
    const table = tr?.closest("table")
    if (!tr || !table) return null

    return { row: Array.from(table.rows).indexOf(tr), col: Array.from(tr.cells).indexOf(cell) }
  }

  columnCount(table) {
    return Math.max(0, ...Array.from(table?.rows ?? []).map((tr) => tr.cells.length))
  }

  hasHeader(table) {
    return table?.rows[0]?.cells[0]?.tagName === "TH"
  }

  alignOfColumn(table, col) {
    const cell = table?.rows[0]?.cells[col]
    return ALIGNMENTS.find((a) => cell?.classList.contains(`rt-al-${a}`)) || "left"
  }
}
