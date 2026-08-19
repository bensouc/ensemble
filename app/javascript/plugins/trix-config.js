// Configuration Trix — appliquée à l'import du bundle, donc AVANT que le moindre
// <trix-editor> ne s'initialise ou ne parse du contenu existant.
//
// C'est important : les attributs de texte maison (souligné, couleurs) doivent
// être enregistrés avant le parsing, sinon le contenu déjà en base est relu
// comme du style inline anonyme et les boutons ne reflètent plus son état.
// L'ancienne version les déclarait dans un `initialize()` Stimulus, donc en
// course avec l'initialisation de l'éditeur.
import Trix from "trix"

// ---------------------------------------------------------------------------
// 1. Libellés (l'app est entièrement en français)
// ---------------------------------------------------------------------------
Object.assign(Trix.config.lang, {
  attachFiles: "Insérer une image",
  bold: "Gras",
  bullets: "Liste à puces",
  captionPlaceholder: "Légende…",
  code: "Code",
  heading1: "Titre",
  indent: "Augmenter le retrait",
  italic: "Italique",
  link: "Lien",
  numbers: "Liste numérotée",
  outdent: "Diminuer le retrait",
  quote: "Citation",
  redo: "Rétablir",
  remove: "Supprimer",
  strike: "Barré",
  undo: "Annuler",
  unlink: "Retirer le lien",
  url: "Adresse",
  urlPlaceholder: "Collez ou saisissez une adresse…",
  // Ajouts maison
  heading2: "Sous-titre",
  heading3: "Petit titre",
  highlight: "Surligner",
  table: "Tableau",
  textColor: "Couleur du texte",
  underline: "Souligné"
})

// ---------------------------------------------------------------------------
// 2. Attributs de texte
//    Déclarations identiques à l'existant : le contenu déjà enregistré
//    (<span style="text-decoration: underline">, style="color: …") se relit à
//    l'identique. Ne pas passer `underline` en <u> sous peine de casser la
//    relecture des énoncés existants.
// ---------------------------------------------------------------------------
Trix.config.textAttributes.underline = {
  style: { textDecoration: "underline" },
  parser: (element) => element.style.textDecoration === "underline",
  inheritable: 1
}

Trix.config.textAttributes.foregroundColor = {
  styleProperty: "color",
  inheritable: 1
}

Trix.config.textAttributes.backgroundColor = {
  styleProperty: "background-color",
  inheritable: 1
}

// Conservé : des énoncés existants peuvent porter cet attribut.
Trix.config.textAttributes.underlineColor = {
  styleProperty: "text-decoration-color",
  inheritable: 1
}

// ---------------------------------------------------------------------------
// 3. Niveaux de titre supplémentaires
//    Trix ne fournit que `heading1`. Ajout purement additif : le contenu
//    existant n'a que des <h1>, il continue de se comporter pareil.
// ---------------------------------------------------------------------------
Trix.config.blockAttributes.heading2 = { tagName: "h2", terminal: true, breakOnReturn: true, group: false }
Trix.config.blockAttributes.heading3 = { tagName: "h3", terminal: true, breakOnReturn: true, group: false }

// ---------------------------------------------------------------------------
// 4. Toolbar
// ---------------------------------------------------------------------------
const IS_MAC = /Mac|^iP/.test(navigator.platform)
const MOD = IS_MAC ? "⌘" : "Ctrl+"

// "shift+z" -> "⌘⇧Z" / "Ctrl+Shift+Z"
function shortcutLabel(key) {
  const parts = key.split("+")
  const letter = parts.pop().toUpperCase()
  const shift = parts.includes("shift") ? (IS_MAC ? "⇧" : "Shift+") : ""
  return `${MOD}${shift}${letter}`
}

function icon(paths) {
  return `<svg class="rt-tb__icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">${paths}</svg>`
}

function glyph(text, variant) {
  return `<span class="rt-tb__glyph rt-tb__glyph--${variant}" aria-hidden="true">${text}</span>`
}

const ICONS = {
  bold: glyph("B", "bold"),
  italic: glyph("I", "italic"),
  underline: glyph("U", "underline"),
  strike: glyph("S", "strike"),
  textColor: icon('<path d="M5.5 16 12 4l6.5 12"/><path d="M8 12.5h8"/>'),
  highlight: icon('<path d="m8.5 14.5 5.5-5.5 3 3-5.5 5.5H8.5z"/><path d="M14 9 16.5 6.5"/><path d="M5.5 20h13"/>'),
  quote: icon('<path d="M5 5v14" stroke-width="2.5"/><path d="M10 8h9M10 12h9M10 16h6"/>'),
  code: icon('<path d="m9 8-4 4 4 4M15 8l4 4-4 4"/>'),
  bullets: icon('<path d="M9 6h11M9 12h11M9 18h11"/><circle cx="4.75" cy="6" r="1.1" style="fill:currentColor;stroke:none"/><circle cx="4.75" cy="12" r="1.1" style="fill:currentColor;stroke:none"/><circle cx="4.75" cy="18" r="1.1" style="fill:currentColor;stroke:none"/>'),
  numbers: icon('<path d="M10 6h10M10 12h10M10 18h10"/><text x="2.6" y="8.4" font-size="7.5" font-weight="600" style="fill:currentColor;stroke:none">1</text><text x="2.6" y="14.4" font-size="7.5" font-weight="600" style="fill:currentColor;stroke:none">2</text><text x="2.6" y="20.4" font-size="7.5" font-weight="600" style="fill:currentColor;stroke:none">3</text>'),
  outdent: icon('<path d="M20 6H4M20 12h-9M20 18H4"/><path d="m7.5 9-3 3 3 3"/>'),
  indent: icon('<path d="M4 6h16M11 12h9M4 18h16"/><path d="m4.5 9 3 3-3 3"/>'),
  attach: icon('<rect x="3.5" y="4.5" width="17" height="15" rx="2.5"/><path d="m4 16.5 4.5-4.5 3.5 3.5 3-3 5 5"/><circle cx="15.5" cy="9" r="1.6"/>'),
  link: icon('<path d="m9.5 14.5 5-5"/><path d="M13 7.5 14.5 6a4 4 0 0 1 5.5 5.5L18.5 13"/><path d="M11 16.5 9.5 18A4 4 0 0 1 4 12.5L5.5 11"/>'),
  undo: icon('<path d="m9 14-5-5 5-5"/><path d="M4 9h9.5a6 6 0 0 1 0 12H8"/>'),
  redo: icon('<path d="m15 14 5-5-5-5"/><path d="M20 9h-9.5a6 6 0 0 0 0 12H16"/>')
}

// Nuanciers alignés sur la palette de l'app (config/_colors.scss) plutôt que sur
// des couleurs inventées : ce qui est écrit dans un énoncé reste cohérent avec
// le reste de l'interface.
const TEXT_SWATCHES = [
  ["Noir", "#3D3D3D"],
  ["Gris", "#9C9C9C"],
  ["Rose", "#F24150"],
  ["Marron", "#C44003"],
  ["Orange", "#E67E22"],
  ["Vert", "#4CAF50"],
  ["Bleu", "#167FFB"],
  ["Violet", "#7C5CE7"]
]

const HIGHLIGHT_SWATCHES = [
  ["Jaune", "#FFF59D"],
  ["Rose clair", "#FAD3D0"],
  ["Orange clair", "#FFE3CF"],
  ["Vert clair", "#C8E6C9"],
  ["Bleu clair", "#C8E6FB"],
  ["Violet clair", "#E7E4FA"],
  ["Gris clair", "#F0F0F0"],
  ["Blanc", "#FFFFFF"]
]

function button({ label, glyph, attribute, action, key, extraClass = "" }) {
  const hint = key ? ` (${shortcutLabel(key)})` : ""
  return `<button type="button" class="trix-button rt-tb__btn ${extraClass}"` +
    (attribute ? ` data-trix-attribute="${attribute}"` : "") +
    (action ? ` data-trix-action="${action}"` : "") +
    (key ? ` data-trix-key="${key}"` : "") +
    ` title="${label}${hint}" aria-label="${label}${hint}" tabindex="-1">` +
    `${glyph}<span class="visually-hidden">${label}</span></button>`
}

function headingButton(attribute, level, label) {
  return `<button type="button" class="trix-button rt-tb__btn rt-tb__btn--text"
    data-trix-attribute="${attribute}" title="${label}" aria-label="${label}" tabindex="-1">
    <span class="rt-tb__glyph rt-tb__glyph--heading" aria-hidden="true">H${level}</span><span class="visually-hidden">${label}</span>
  </button>`
}

function palette({ attribute, label, glyph, swatches, clearLabel }) {
  const chips = swatches.map(([name, value]) => `
    <button type="button" class="rt-tb__chip" style="--rt-chip: ${value}"
      data-action="trix-palette#pick" data-color="${value}"
      title="${name}" aria-label="${name}" tabindex="-1"></button>`).join("")

  return `<span class="rt-tb__palette" data-controller="trix-palette"
    data-trix-palette-attribute-value="${attribute}"
    data-action="keydown->trix-palette#keydown">
    <button type="button" class="trix-button rt-tb__btn rt-tb__btn--palette"
      data-action="trix-palette#toggle" data-trix-palette-target="trigger"
      aria-haspopup="dialog" aria-expanded="false"
      title="${label}" aria-label="${label}" tabindex="-1">
      ${glyph}
      <span class="rt-tb__swatch" data-trix-palette-target="preview" aria-hidden="true"></span>
      <span class="visually-hidden">${label}</span>
    </button>
    <div class="rt-tb__popover" data-trix-palette-target="panel" role="dialog" aria-label="${label}" hidden>
      <div class="rt-tb__chips">${chips}</div>
      <div class="rt-tb__popover-footer">
        <label class="rt-tb__custom">
          <input type="color" data-action="change->trix-palette#pickCustom" aria-label="Couleur personnalisée">
          <span aria-hidden="true">Autre…</span>
        </label>
        <button type="button" class="rt-tb__clear" data-action="trix-palette#clear" tabindex="-1">${clearLabel}</button>
      </div>
    </div>
  </span>`
}

Trix.config.toolbar.getDefaultHTML = function () {
  const lang = Trix.config.lang

  return `
<div class="trix-button-row rt-tb" role="toolbar" aria-label="Mise en forme"
     data-controller="rt-toolbar"
     data-action="keydown->rt-toolbar#keydown focusin->rt-toolbar#focusin">
  <span class="trix-button-group trix-button-group--text-tools rt-tb__group" data-trix-button-group="text-tools">
    ${button({ label: lang.bold, glyph: ICONS.bold, attribute: "bold", key: "b" })}
    ${button({ label: lang.italic, glyph: ICONS.italic, attribute: "italic", key: "i" })}
    ${button({ label: lang.underline, glyph: ICONS.underline, attribute: "underline", key: "u" })}
    ${button({ label: lang.strike, glyph: ICONS.strike, attribute: "strike" })}
  </span>

  <span class="trix-button-group rt-tb__group" data-trix-button-group="color-tools">
    ${palette({
      attribute: "foregroundColor",
      label: lang.textColor,
      glyph: ICONS.textColor,
      swatches: TEXT_SWATCHES,
      clearLabel: "Couleur par défaut"
    })}
    ${palette({
      attribute: "backgroundColor",
      label: lang.highlight,
      glyph: ICONS.highlight,
      swatches: HIGHLIGHT_SWATCHES,
      clearLabel: "Retirer le surlignage"
    })}
  </span>

  <span class="trix-button-group trix-button-group--block-tools rt-tb__group" data-trix-button-group="block-tools">
    ${headingButton("heading1", 1, lang.heading1)}
    ${headingButton("heading2", 2, lang.heading2)}
    ${headingButton("heading3", 3, lang.heading3)}
    ${button({ label: lang.quote, glyph: ICONS.quote, attribute: "quote" })}
    ${button({ label: lang.code, glyph: ICONS.code, attribute: "code" })}
    ${button({ label: lang.bullets, glyph: ICONS.bullets, attribute: "bullet" })}
    ${button({ label: lang.numbers, glyph: ICONS.numbers, attribute: "number" })}
    ${button({ label: lang.outdent, glyph: ICONS.outdent, action: "decreaseNestingLevel" })}
    ${button({ label: lang.indent, glyph: ICONS.indent, action: "increaseNestingLevel" })}
  </span>

  <span class="trix-button-group trix-button-group--file-tools rt-tb__group" data-trix-button-group="file-tools">
    ${button({ label: lang.attachFiles, glyph: ICONS.attach, action: "attachFiles" })}
    ${button({ label: lang.link, glyph: ICONS.link, attribute: "href", action: "link", key: "k" })}
  </span>

  <span class="trix-button-group-spacer"></span>

  <span class="trix-button-group trix-button-group--history-tools rt-tb__group" data-trix-button-group="history-tools">
    ${button({ label: lang.undo, glyph: ICONS.undo, action: "undo", key: "z" })}
    ${button({ label: lang.redo, glyph: ICONS.redo, action: "redo", key: "shift+z" })}
  </span>
</div>

<div class="trix-dialogs rt-tb__dialogs" data-trix-dialogs>
  <div class="trix-dialog trix-dialog--link rt-tb__dialog" data-trix-dialog="href" data-trix-dialog-attribute="href">
    <div class="trix-dialog__link-fields rt-tb__dialog-fields">
      <input type="url" name="href" class="trix-input trix-input--dialog rt-tb__dialog-input"
             placeholder="${lang.urlPlaceholder}" aria-label="${lang.url}"
             required data-trix-validate-href data-trix-input>
      <div class="trix-button-group">
        <input type="button" class="trix-button trix-button--dialog rt-tb__dialog-btn rt-tb__dialog-btn--primary"
               value="${lang.link}" data-trix-method="setAttribute">
        <input type="button" class="trix-button trix-button--dialog rt-tb__dialog-btn"
               value="${lang.unlink}" data-trix-method="removeAttribute">
      </div>
    </div>
  </div>
</div>`
}
