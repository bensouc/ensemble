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
const MAX_ROWS = 60
const MAX_COLUMNS = 20

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

    // Trix retire `contenteditable` du balisage des pièces jointes et re-rend
    // la vue à chaque render (annulation, insertion…) : on repose l'attribut à
    // chaque fois.
    this.element.addEventListener("trix-initialize", this.hydrate)
    this.element.addEventListener("trix-render", this.hydrate)
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

    // Les événements Trix couvrent le cas courant, mais le premier rendu du
    // document est planifié dans une frame d'animation : selon l'ordre des
    // callbacks, `trix-initialize` peut précéder l'insertion des cellules.
    // Un observateur scopé à l'éditeur ferme la fenêtre — `hydrate` est
    // idempotent (`:not([contenteditable])`), donc sans boucle de rétroaction.
    this.observer = new MutationObserver(() => this.hydrate())
    this.observer.observe(this.element, { childList: true, subtree: true })

    this.hydrate()
  }

  disconnect() {
    this.pending.forEach((timer) => clearTimeout(timer))
    this.pending.clear()
    this.observer?.disconnect()

    this.element.removeEventListener("trix-initialize", this.hydrate)
    this.element.removeEventListener("trix-render", this.hydrate)
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
    // Empêche le clic sur un bouton de la toolbar de sortir le focus de la
    // cellule courante : les actions de style et d'alignement en dépendent.
    if (this.buttonFor(event.target)) {
      event.preventDefault()
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

      const root = button.closest(".rt-table--editor, .table-editor")
      if (root) this.runAction(root, button)
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
            this.toggleStyle(root, cell, flag)
          }
        }
    }
  }

  onInput(event) {
    const cell = this.cellFor(event.target)
    if (!cell) return

    event.stopPropagation()
    const root = cell.closest(".rt-table--editor, .table-editor")
    if (root) this.scheduleSave(root)
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

    this.scheduleSave(root, { immediate: true })
  }

  onFocusIn(event) {
    const cell = this.cellFor(event.target)
    if (cell) this.activeCell = cell
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
    this.scheduleSave(root, { immediate: true, syncSnapshot: !staysInside })
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

  runAction(root, button) {
    const table = root.querySelector("table")
    if (!table) return

    const cell = this.activeCellIn(root)
    const { row, col } = this.positionOf(cell) ?? { row: null, col: null }

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
    else {
      const flag = STYLE_FLAGS.find((f) => classes.contains(`rt-t-style-${f}`))
      if (flag && cell) this.toggleStyle(root, cell, flag)
      else return
    }

    this.hydrate()
    this.scheduleSave(root, { immediate: true })
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

  toggleStyle(root, cell, flag) {
    cell.classList.toggle(`rt-c-${flag}`)
    this.scheduleSave(root, { immediate: true })
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

  scheduleSave(root, { immediate = false, syncSnapshot = false } = {}) {
    clearTimeout(this.pending.get(root))

    if (immediate) {
      this.pending.delete(root)
      this.save(root, { syncSnapshot })
      return
    }

    this.pending.set(root, setTimeout(() => {
      this.pending.delete(root)
      this.save(root)
    }, SAVE_DELAY))
  }

  async flushAll() {
    const roots = new Set(this.pending.keys())
    roots.forEach((root) => clearTimeout(this.pending.get(root)))
    this.pending.clear()

    // Avant envoi du formulaire, le focus n'a plus d'importance : on
    // resynchronise l'instantané de chaque tableau.
    await Promise.all([...roots].map((root) => this.save(root, { syncSnapshot: true })))
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
  async save(root, { syncSnapshot = false } = {}) {
    const sgid = this.sgidFor(root)
    if (!sgid) return

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
        if (syncSnapshot && payload?.content) this.syncSnapshot(root, sgid, payload.content)
      })
      .catch((error) => {
        console.error("Enregistrement du tableau impossible", error)
      })

    this.inFlight.add(promise)
    await promise
    this.inFlight.delete(promise)
  }

  syncSnapshot(root, sgid, content) {
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
      col_aligns: colAligns
    }
  }

  // --- Utilitaires ---------------------------------------------------------

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

  activeCellIn(root) {
    return this.activeCell && root.contains(this.activeCell) ? this.activeCell : null
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
