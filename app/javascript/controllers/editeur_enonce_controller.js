import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"
import { post } from "@rails/request.js"
import { pourLEditeur, pourLEnregistrement } from "../editeur/blocs"

// Éditeur d'énoncé d'exercice (TipTap), à la place de Trix.
//
// Le champ caché `input` porte le corps au format qu'ActionText échange avec
// Trix ; il est réécrit à chaque modification par `editor.getHTML()` — jamais en
// lisant le DOM de l'éditeur, qui contient des artefacts de ProseMirror
// (Osponso les a vus s'accumuler à chaque enregistrement).
//
// La barre reprend celle de Trix (mêmes classes `rt-tb__*`, donc même allure).
//
// TipTap n'est chargé qu'ici, à la demande (`import()`) : il pèse autant que tout
// le reste du JS de l'app, et ne sert qu'au formulaire d'exercice.

const MOD = /Mac|^iP/.test(navigator.platform) ? "⌘" : "Ctrl+"

function icone(traces) {
  return `<svg class="rt-tb__icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">${traces}</svg>`
}

const ICONES = {
  textColor: icone('<path d="M5.5 16 12 4l6.5 12"/><path d="M8 12.5h8"/>'),
  highlight: icone('<path d="m8.5 14.5 5.5-5.5 3 3-5.5 5.5H8.5z"/><path d="M14 9 16.5 6.5"/><path d="M5.5 20h13"/>'),
  quote: icone('<path d="M5 5v14" stroke-width="2.5"/><path d="M10 8h9M10 12h9M10 16h6"/>'),
  code: icone('<path d="m9 8-4 4 4 4M15 8l4 4-4 4"/>'),
  bullets: icone('<path d="M9 6h11M9 12h11M9 18h11"/><circle cx="4.75" cy="6" r="1.1" style="fill:currentColor;stroke:none"/><circle cx="4.75" cy="12" r="1.1" style="fill:currentColor;stroke:none"/><circle cx="4.75" cy="18" r="1.1" style="fill:currentColor;stroke:none"/>'),
  numbers: icone('<path d="M10 6h10M10 12h10M10 18h10"/><text x="2.6" y="8.4" font-size="7.5" font-weight="600" style="fill:currentColor;stroke:none">1</text><text x="2.6" y="14.4" font-size="7.5" font-weight="600" style="fill:currentColor;stroke:none">2</text><text x="2.6" y="20.4" font-size="7.5" font-weight="600" style="fill:currentColor;stroke:none">3</text>'),
  outdent: icone('<path d="M20 6H4M20 12h-9M20 18H4"/><path d="m7.5 9-3 3 3 3"/>'),
  indent: icone('<path d="M4 6h16M11 12h9M4 18h16"/><path d="m4.5 9 3 3-3 3"/>'),
  attach: icone('<rect x="3.5" y="4.5" width="17" height="15" rx="2.5"/><path d="m4 16.5 4.5-4.5 3.5 3.5 3-3 5 5"/><circle cx="15.5" cy="9" r="1.6"/>'),
  table: icone('<rect x="3.5" y="4.5" width="17" height="15" rx="2"/><path d="M3.5 10h17M3.5 15h17M10 4.5v15"/>'),
  // Des formes géométriques : le menu ne contient pas que des horloges (lignes
  // d'écriture, pictogrammes aussi), l'horloge en icône le laissait croire.
  figure: icone('<circle cx="7.5" cy="7.5" r="4"/><rect x="13" y="3.5" width="7.5" height="7.5" rx="1"/><path d="M12 13.5 16.5 20.5h-9z"/>'),
  link: icone('<path d="m9.5 14.5 5-5"/><path d="M13 7.5 14.5 6a4 4 0 0 1 5.5 5.5L18.5 13"/><path d="M11 16.5 9.5 18A4 4 0 0 1 4 12.5L5.5 11"/>'),
  undo: icone('<path d="m9 14-5-5 5-5"/><path d="M4 9h9.5a6 6 0 0 1 0 12H8"/>'),
  redo: icone('<path d="m15 14 5-5-5-5"/><path d="M20 9h-9.5a6 6 0 0 0 0 12H16"/>'),
  ligneAvant: icone('<rect x="3.5" y="9.5" width="17" height="10" rx="1.5"/><path d="M12 2.5v5M9.5 5h5"/>'),
  ligneApres: icone('<rect x="3.5" y="4.5" width="17" height="10" rx="1.5"/><path d="M12 16.5v5M9.5 19h5"/>'),
  colonneAvant: icone('<rect x="9.5" y="3.5" width="10" height="17" rx="1.5"/><path d="M2.5 12h5M5 9.5v5"/>'),
  colonneApres: icone('<rect x="4.5" y="3.5" width="10" height="17" rx="1.5"/><path d="M16.5 12h5M19 9.5v5"/>'),
  ligneSuppr: icone('<rect x="3.5" y="7.5" width="17" height="9" rx="1.5"/><path d="m9.5 10 5 4M14.5 10l-5 4"/>'),
  colonneSuppr: icone('<rect x="7.5" y="3.5" width="9" height="17" rx="1.5"/><path d="m10 9.5 4 5M14 9.5l-4 5"/>'),
  entete: icone('<rect x="3.5" y="4.5" width="17" height="15" rx="2"/><path d="M3.5 9.5h17"/><path d="M3.5 4.5h17v5h-17z" style="fill:currentColor;opacity:.35"/>'),
  colonnes: icone('<rect x="3.5" y="4.5" width="7.5" height="15" rx="1.5"/><rect x="13" y="4.5" width="7.5" height="15" rx="1.5"/>'),
  tableSuppr: icone('<rect x="3.5" y="4.5" width="17" height="15" rx="2"/><path d="m9 9.5 6 6M15 9.5l-6 6"/>')
}

const ALIGNEMENTS = [
  { valeur: "left", nom: "Aligner à gauche", trace: '<path d="M4 6h16M4 12h10M4 18h13"/>' },
  { valeur: "center", nom: "Centrer", trace: '<path d="M4 6h16M7 12h10M5.5 18h13"/>' },
  { valeur: "right", nom: "Aligner à droite", trace: '<path d="M4 6h16M10 12h10M7 18h13"/>' },
  { valeur: "justify", nom: "Justifier", trace: '<path d="M4 6h16M4 12h16M4 18h16"/>' }
]

// Trois lignes d'autant plus écartées que l'interligne est grand, et la flèche
// qui mesure l'écart.
function traceInterligne(hauteur) {
  const e = Math.round(35 * hauteur) / 10
  const haut = 12 - e, bas = 12 + e
  return `<path d="M9 ${haut}h11M9 12h11M9 ${bas}h11"/><path d="M4.5 ${haut}V${bas}"/>` +
    `<path d="m2.6 ${haut + 1.9} 1.9-1.9 1.9 1.9M2.6 ${bas - 1.9}l1.9 1.9 1.9-1.9"/>`
}

// « normal » n'écrit rien : le paragraphe prend l'interligne 1,4 de `.rt-p`.
const INTERLIGNES = [
  { valeur: "1", nom: "Interligne 1", hauteur: 1 },
  { valeur: "1.2", nom: "Interligne 1,2", hauteur: 1.2 },
  { valeur: "normal", nom: "Interligne normal (1,4)", hauteur: 1.4 },
  { valeur: "1.6", nom: "Interligne 1,6", hauteur: 1.6 },
  { valeur: "2", nom: "Interligne 2", hauteur: 2 }
].map((o) => ({ ...o, trace: traceInterligne(o.hauteur) }))

// Un interligne qui n'est plus au menu (2,5 et 3 l'ont été) s'affiche comme le
// plus proche.
function interligneDuMenu(lineHeight) {
  if (!lineHeight) return "normal"
  const v = Number(lineHeight)
  return INTERLIGNES.reduce((a, b) => (Math.abs(b.hauteur - v) < Math.abs(a.hauteur - v) ? b : a)).valeur
}

// En `em` : la taille suit celle de l'énoncé, plus grande au PDF qu'à l'écran.
const lettre = (taille, y) =>
  `<text x="12" y="${y}" font-size="${taille}" font-weight="600" text-anchor="middle" style="fill:currentColor;stroke:none">A</text>`
const TAILLES = [
  { valeur: "0.85em", nom: "Petit", trace: lettre(12, 16.5) },
  { valeur: "normal", nom: "Normal", trace: lettre(16, 18) },
  { valeur: "1.25em", nom: "Grand", trace: lettre(20, 19.5) },
  { valeur: "1.5em", nom: "Très grand", trace: lettre(24, 21) }
]

const COLONNES = [
  { valeur: "2", nom: "Deux colonnes", trace: '<rect x="3.5" y="4.5" width="7.5" height="15" rx="1.5"/><rect x="13" y="4.5" width="7.5" height="15" rx="1.5"/>' },
  { valeur: "3", nom: "Trois colonnes", trace: '<rect x="2.5" y="4.5" width="5.5" height="15" rx="1"/><rect x="9.25" y="4.5" width="5.5" height="15" rx="1"/><rect x="16" y="4.5" width="5.5" height="15" rx="1"/>' },
  { valeur: "aucune", nom: "Retirer les colonnes", trace: '<rect x="3.5" y="4.5" width="17" height="15" rx="1.5"/><path d="M12 4.5v15" stroke-dasharray="2 2"/>' }
]

// Nuanciers de la toolbar de Trix (trix-config.js), donc de la palette de l'app.
const COULEURS_TEXTE = [["Noir", "#3D3D3D"], ["Gris", "#9C9C9C"], ["Rose", "#F24150"], ["Marron", "#C44003"],
  ["Orange", "#E67E22"], ["Vert", "#4CAF50"], ["Bleu", "#167FFB"], ["Violet", "#7C5CE7"]]
const COULEURS_SURLIGNAGE = [["Jaune", "#FFF59D"], ["Rose clair", "#FAD3D0"], ["Orange clair", "#FFE3CF"],
  ["Vert clair", "#C8E6C9"], ["Bleu clair", "#C8E6FB"], ["Violet clair", "#E7E4FA"], ["Gris clair", "#F0F0F0"], ["Blanc", "#FFFFFF"]]

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

function bouton({ commande, libelle, glyphe, raccourci = "", classe = "", valeur = "" }) {
  const indice = raccourci ? ` (${MOD}${raccourci})` : ""
  return `<button type="button" class="trix-button rt-tb__btn ${classe}" data-commande="${commande}"
    ${valeur ? `data-valeur="${valeur}"` : ""} title="${libelle}${indice}" aria-label="${libelle}${indice}" tabindex="-1">
    ${glyphe}<span class="visually-hidden">${libelle}</span></button>`
}

function glyphe(texte, variante) {
  return `<span class="rt-tb__glyph rt-tb__glyph--${variante}" aria-hidden="true">${texte}</span>`
}

function nuancier({ nom, libelle, glyphe: g, couleurs, effacer }) {
  const pastilles = couleurs.map(([n, v]) => `<button type="button" class="rt-tb__chip" style="--rt-chip: ${v}"
    data-nuancier="${nom}" data-couleur="${v}" title="${n}" aria-label="${n}" tabindex="-1"></button>`).join("")
  return `<span class="rt-tb__palette" data-popover>
    <button type="button" class="trix-button rt-tb__btn rt-tb__btn--palette" data-ouvrir aria-haspopup="dialog"
      aria-expanded="false" title="${libelle}" aria-label="${libelle}" tabindex="-1">${g}
      <span class="rt-tb__swatch" data-apercu="${nom}" aria-hidden="true"></span><span class="visually-hidden">${libelle}</span></button>
    <div class="rt-tb__popover" role="dialog" aria-label="${libelle}" hidden>
      <div class="rt-tb__chips">${pastilles}</div>
      <div class="rt-tb__popover-footer">
        <label class="rt-tb__custom"><input type="color" data-nuancier-libre="${nom}" aria-label="Couleur personnalisée"><span aria-hidden="true">Autre…</span></label>
        <button type="button" class="rt-tb__clear" data-nuancier="${nom}" data-couleur="" tabindex="-1">${effacer}</button>
      </div>
    </div>
  </span>`
}

function menu({ nom, libelle, options }) {
  const items = options.map(({ valeur, nom: n, trace }) => `
    <button type="button" class="rt-tb__menu-item" role="menuitemradio" aria-checked="false"
      data-menu="${nom}" data-valeur="${valeur}" tabindex="-1">${icone(trace)}<span>${n}</span></button>`).join("")
  return `<span class="rt-tb__palette" data-popover>
    <button type="button" class="trix-button rt-tb__btn rt-tb__btn--palette" data-ouvrir aria-haspopup="menu"
      aria-expanded="false" title="${libelle}" aria-label="${libelle}" tabindex="-1">
      <span class="rt-tb__align-preview" data-apercu-menu="${nom}" aria-hidden="true"></span><span class="visually-hidden">${libelle}</span></button>
    <div class="rt-tb__popover rt-tb__popover--menu" role="menu" aria-label="${libelle}" hidden>${items}</div>
  </span>`
}

function menuFigures() {
  const pictos = PICTOS.map(([nom, libelle, traits]) => `
    <button type="button" class="rt-figures__picto" data-picto="${nom}"
            title="${libelle}" aria-label="Insérer le pictogramme « ${libelle} »" tabindex="-1">${pictoSvg(traits)}</button>`).join("")
  return `<span class="rt-tb__palette rt-figures" data-popover>
    <button type="button" class="trix-button rt-tb__btn" data-ouvrir aria-haspopup="dialog" aria-expanded="false"
            title="Insérer une figure" aria-label="Insérer une figure" tabindex="-1">${ICONES.figure}
      <span class="visually-hidden">Insérer une figure</span></button>
    <div class="rt-tb__popover rt-figures__panel" role="dialog" aria-label="Insérer une figure" hidden>
      <div class="rt-figures__section">
        <span class="rt-figures__titre">Ligne d'écriture</span>
        <div class="rt-figures__rangee rt-figures__rangee--lignes">
          <button type="button" class="rt-figures__choix" data-ligne="seyes" tabindex="-1"><span class="rt-figures__apercu rt-seyes" aria-hidden="true"></span>Seyès</button>
          <button type="button" class="rt-figures__choix" data-ligne="seyes-marge" tabindex="-1"><span class="rt-figures__apercu rt-seyes rt-seyes--marge" aria-hidden="true"></span>Seyès avec marge</button>
          <button type="button" class="rt-figures__choix" data-ligne="ligne" tabindex="-1"><span class="rt-figures__apercu rt-ligne" aria-hidden="true"></span>Ligne simple</button>
          <button type="button" class="rt-figures__choix" data-ligne="carreaux" tabindex="-1"><span class="rt-figures__apercu rt-carreaux" aria-hidden="true"></span>Petits carreaux</button>
        </div>
      </div>
      <div class="rt-figures__section">
        <span class="rt-figures__titre">Horloge</span>
        <div class="rt-figures__rangee">
          <input type="text" class="rt-figures__heure" inputmode="numeric" placeholder="3:15" maxlength="5"
                 aria-label="Heure de l'horloge, vide pour une horloge sans aiguilles">
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
  </span>`
}

function barreHtml() {
  return `<div class="trix-button-row rt-tb" role="toolbar" aria-label="Mise en forme">
    <span class="trix-button-group rt-tb__group">
      ${bouton({ commande: "bold", libelle: "Gras", glyphe: glyphe("B", "bold"), raccourci: "B" })}
      ${bouton({ commande: "italic", libelle: "Italique", glyphe: glyphe("I", "italic"), raccourci: "I" })}
      ${bouton({ commande: "underline", libelle: "Souligné", glyphe: glyphe("U", "underline"), raccourci: "U" })}
      ${bouton({ commande: "strike", libelle: "Barré", glyphe: glyphe("S", "strike") })}
    </span>
    <span class="trix-button-group rt-tb__group">
      ${nuancier({ nom: "texte", libelle: "Couleur du texte", glyphe: ICONES.textColor, couleurs: COULEURS_TEXTE, effacer: "Couleur par défaut" })}
      ${nuancier({ nom: "surlignage", libelle: "Surligner", glyphe: ICONES.highlight, couleurs: COULEURS_SURLIGNAGE, effacer: "Retirer le surlignage" })}
      ${menu({ nom: "taille", libelle: "Taille du texte", options: TAILLES })}
    </span>
    <span class="trix-button-group rt-tb__group">
      ${bouton({ commande: "heading", valeur: "1", libelle: "Titre", glyphe: glyphe("H1", "heading"), classe: "rt-tb__btn--text" })}
      ${bouton({ commande: "heading", valeur: "2", libelle: "Sous-titre", glyphe: glyphe("H2", "heading"), classe: "rt-tb__btn--text" })}
      ${bouton({ commande: "heading", valeur: "3", libelle: "Petit titre", glyphe: glyphe("H3", "heading"), classe: "rt-tb__btn--text" })}
      ${bouton({ commande: "blockquote", libelle: "Citation", glyphe: ICONES.quote })}
      ${bouton({ commande: "codeBlock", libelle: "Code", glyphe: ICONES.code })}
      ${bouton({ commande: "bulletList", libelle: "Liste à puces", glyphe: ICONES.bullets })}
      ${bouton({ commande: "orderedList", libelle: "Liste numérotée", glyphe: ICONES.numbers })}
      ${bouton({ commande: "outdent", libelle: "Diminuer le retrait", glyphe: ICONES.outdent })}
      ${bouton({ commande: "indent", libelle: "Augmenter le retrait", glyphe: ICONES.indent })}
      ${menu({ nom: "alignement", libelle: "Alignement", options: ALIGNEMENTS })}
      ${menu({ nom: "interligne", libelle: "Interligne", options: INTERLIGNES })}
    </span>
    <span class="trix-button-group rt-tb__group">
      ${bouton({ commande: "image", libelle: "Insérer une image", glyphe: ICONES.attach })}
      ${bouton({ commande: "table", libelle: "Tableau", glyphe: ICONES.table })}
      ${menu({ nom: "colonnes", libelle: "Colonnes", options: COLONNES })}
      ${menuFigures()}
      ${bouton({ commande: "link", libelle: "Lien", glyphe: ICONES.link, raccourci: "K", classe: "rt-tb__btn--offscreen" })}
    </span>
    <span class="trix-button-group rt-tb__group rt-barre__tableau" aria-label="Tableau">
      ${bouton({ commande: "addRowBefore", libelle: "Ligne au-dessus", glyphe: ICONES.ligneAvant })}
      ${bouton({ commande: "addRowAfter", libelle: "Ligne en dessous", glyphe: ICONES.ligneApres })}
      ${bouton({ commande: "addColumnBefore", libelle: "Colonne à gauche", glyphe: ICONES.colonneAvant })}
      ${bouton({ commande: "addColumnAfter", libelle: "Colonne à droite", glyphe: ICONES.colonneApres })}
      ${bouton({ commande: "deleteRow", libelle: "Supprimer la ligne", glyphe: ICONES.ligneSuppr })}
      ${bouton({ commande: "deleteColumn", libelle: "Supprimer la colonne", glyphe: ICONES.colonneSuppr })}
      ${bouton({ commande: "toggleHeaderRow", libelle: "Ligne d'en-tête", glyphe: ICONES.entete })}
      ${bouton({ commande: "deleteTable", libelle: "Supprimer le tableau", glyphe: ICONES.tableSuppr })}
    </span>
    <span class="trix-button-group-spacer"></span>
    <span class="trix-button-group rt-tb__group">
      ${bouton({ commande: "undo", libelle: "Annuler", glyphe: ICONES.undo, raccourci: "Z" })}
      ${bouton({ commande: "redo", libelle: "Rétablir", glyphe: ICONES.redo, raccourci: "⇧Z" })}
    </span>
  </div>`
}

export default class extends Controller {
  static targets = ["input", "barre", "zone", "fichier"]
  static values = { directUploadUrl: String, blobUrlTemplate: String, placeholder: String }

  async connect() {
    // Une connexion précédente (cache Turbo) a pu laisser sa barre derrière elle.
    this.barreTarget.innerHTML = barreHtml()
    this.zoneTarget.innerHTML = ""

    const [{ Editor }, { extensionsDeLEditeur }] = await Promise.all([
      import("@tiptap/core"),
      import("../editeur/extensions")
    ])
    // Le formulaire a pu être refermé pendant le chargement.
    if (!this.element.isConnected || this.editor) return

    this.editor = new Editor({
      element: this.zoneTarget,
      extensions: extensionsDeLEditeur({ placeholder: this.placeholderValue }),
      content: pourLEditeur(this.inputTarget.value),
      editorProps: {
        attributes: { class: "trix-content rt-editeur__contenu" },
        transformPastedHTML: pourLEditeur,
        handlePaste: (_view, event) => this.fichiersDepuis(event.clipboardData),
        handleDrop: (_view, event) => this.fichiersDepuis(event.dataTransfer)
      },
      onUpdate: () => this.synchroniser(),
      onSelectionUpdate: () => this.etatBarre(),
      onTransaction: () => this.etatBarre()
    })

    this.onClicBarre = this.onClicBarre.bind(this)
    this.onClicDehors = this.onClicDehors.bind(this)
    this.onChangerHeure = this.onChangerHeure.bind(this)
    this.barreTarget.addEventListener("mousedown", (e) => {
      // Garder la sélection de l'énoncé quand on clique un bouton ; laisser
      // vivre les champs (heure, couleur libre).
      if (!e.target.closest("input, label")) e.preventDefault()
    })
    this.barreTarget.addEventListener("click", this.onClicBarre)
    this.barreTarget.addEventListener("input", (e) => this.onCouleurLibre(e))
    this.barreTarget.querySelector(".rt-figures__heure").addEventListener("keydown", (e) => {
      if (e.key === "Enter") { e.preventDefault(); this.insererHorloge() }
    })
    this.element.addEventListener("piece-jointe:changer-heure", this.onChangerHeure)
    this.element.addEventListener("keydown", (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") { e.preventDefault(); this.lien() }
      if (e.key === "Escape") this.fermerPopovers()
    })
    this.synchroniser()
    this.etatBarre()
  }

  disconnect() {
    document.removeEventListener("pointerdown", this.onClicDehors, true)
    this.editor?.destroy()
  }

  // Toujours le HTML complet : `editor.isEmpty` peut juger vide un énoncé fait
  // d'une seule image, qu'on aurait alors effacé à l'enregistrement.
  synchroniser() {
    this.inputTarget.value = pourLEnregistrement(this.editor.getHTML())
  }

  // --- Barre ---------------------------------------------------------------------

  onClicBarre(event) {
    const cible = event.target.closest("button")
    if (!cible) return
    event.preventDefault()

    if (cible.hasAttribute("data-ouvrir")) return this.basculerPopover(cible.closest("[data-popover]"))
    if (cible.dataset.nuancier) return this.couleur(cible.dataset.nuancier, cible.dataset.couleur)
    if (cible.dataset.menu) return this.choixMenu(cible.dataset.menu, cible.dataset.valeur)
    if (cible.dataset.ligne) {
      const ligne = cible.dataset.ligne
      return this.insererFigure({ kind: ligne === "seyes-marge" ? "seyes" : ligne, marge: ligne === "seyes-marge" })
    }
    if (cible.dataset.picto) return this.insererFigure({ kind: "picto", nom: cible.dataset.picto })
    if (cible.classList.contains("rt-figures__inserer")) return this.insererHorloge()
    if (cible.dataset.commande) return this.commande(cible.dataset.commande, cible.dataset.valeur)
  }

  commande(nom, valeur) {
    const c = this.editor.chain().focus()
    switch (nom) {
      case "bold": return c.toggleBold().run()
      case "italic": return c.toggleItalic().run()
      case "underline": return c.toggleUnderline().run()
      case "strike": return c.toggleStrike().run()
      case "heading": return c.toggleHeading({ level: Number(valeur) }).run()
      case "blockquote": return c.toggleBlockquote().run()
      case "codeBlock": return c.toggleCodeBlock().run()
      case "bulletList": return c.toggleBulletList().run()
      case "orderedList": return c.toggleOrderedList().run()
      case "indent": return c.sinkListItem("listItem").run()
      case "outdent": return c.liftListItem("listItem").run()
      case "undo": return c.undo().run()
      case "redo": return c.redo().run()
      case "image": return this.fichierTarget.click()
      case "table": return c.insertTable({ rows: 3, cols: 3, withHeaderRow: false }).run()
      case "link": return this.lien()
      case "addRowBefore": case "addRowAfter": case "addColumnBefore": case "addColumnAfter":
      case "deleteRow": case "deleteColumn": case "toggleHeaderRow": case "deleteTable":
        return c[nom]().run()
    }
  }

  couleur(nuancier, valeur) {
    const c = this.editor.chain().focus()
    if (nuancier === "texte") valeur ? c.setColor(valeur).run() : c.unsetColor().run()
    // `removeEmptyTextStyle` seulement pour retirer : enchaîné après la pose, il
    // effaçait aussitôt le surlignage d'une case de tableau.
    else if (valeur) c.setMark("textStyle", { backgroundColor: valeur }).run()
    else c.setMark("textStyle", { backgroundColor: null }).removeEmptyTextStyle().run()
    this.fermerPopovers()
  }

  onCouleurLibre(event) {
    const nuancier = event.target.dataset.nuancierLibre
    if (!nuancier) return
    const c = this.editor.chain().focus()
    if (nuancier === "texte") c.setColor(event.target.value).run()
    else c.setMark("textStyle", { backgroundColor: event.target.value }).run()
  }

  choixMenu(menu, valeur) {
    const c = this.editor.chain().focus()
    if (menu === "alignement") c.setTextAlign(valeur).run()
    else if (menu === "colonnes") valeur === "aucune" ? c.retirerColonnes().run() : c.insererColonnes(Number(valeur)).run()
    else if (menu === "taille") valeur === "normal" ? c.unsetFontSize().run() : c.setFontSize(valeur).run()
    else {
      const lineHeight = valeur === "normal" ? null : valeur
      c.updateAttributes("paragraph", { lineHeight }).updateAttributes("heading", { lineHeight }).run()
    }
    this.fermerPopovers()
  }

  lien() {
    const actuel = this.editor.getAttributes("link").href || ""
    const href = window.prompt("Adresse du lien (vide pour le retirer) :", actuel)
    if (href === null) return
    const c = this.editor.chain().focus().extendMarkRange("link")
    href.trim() ? c.setLink({ href: href.trim() }).run() : c.unsetLink().run()
  }

  // État des boutons : enfoncés, grisés, aperçus des nuanciers et menus.
  etatBarre() {
    if (!this.editor) return
    const e = this.editor
    const actif = {
      bold: e.isActive("bold"), italic: e.isActive("italic"), underline: e.isActive("underline"),
      strike: e.isActive("strike"), blockquote: e.isActive("blockquote"), codeBlock: e.isActive("codeBlock"),
      bulletList: e.isActive("bulletList"), orderedList: e.isActive("orderedList")
    }
    this.barreTarget.querySelectorAll("[data-commande]").forEach((b) => {
      const nom = b.dataset.commande
      const enfonce = nom === "heading" ? e.isActive("heading", { level: Number(b.dataset.valeur) }) : !!actif[nom]
      b.classList.toggle("trix-active", enfonce)
      b.setAttribute("aria-pressed", enfonce)
    })

    const dansTableau = e.isActive("table")
    this.barreTarget.querySelectorAll(".rt-barre__tableau [data-commande]").forEach((b) => { b.disabled = !dansTableau })
    const dansListe = e.isActive("listItem")
    this.barreTarget.querySelectorAll('[data-commande="indent"], [data-commande="outdent"]').forEach((b) => { b.disabled = !dansListe })

    const style = e.getAttributes("textStyle")
    this.apercu("texte", style.color)
    this.apercu("surlignage", style.backgroundColor)

    const bloc = e.isActive("heading") ? e.getAttributes("heading") : e.getAttributes("paragraph")
    this.apercuMenu("alignement", bloc.textAlign || "left", ALIGNEMENTS)
    this.apercuMenu("interligne", interligneDuMenu(bloc.lineHeight), INTERLIGNES)
    this.apercuMenu("taille", TAILLES.some((t) => t.valeur === style.fontSize) ? style.fontSize : "normal", TAILLES)
    this.apercuMenu("colonnes", "2", COLONNES)
    const dansColonnes = e.isActive("colonnes")
    this.barreTarget.querySelector('[data-menu="colonnes"][data-valeur="aucune"]').disabled = !dansColonnes
  }

  apercu(nom, couleur) {
    const el = this.barreTarget.querySelector(`[data-apercu="${nom}"]`)
    if (!el) return
    el.style.setProperty("--rt-swatch", couleur || "transparent")
    el.classList.toggle("rt-tb__swatch--empty", !couleur)
  }

  apercuMenu(nom, valeur, options) {
    const choix = options.find((o) => o.valeur === String(valeur)) || options[0]
    const el = this.barreTarget.querySelector(`[data-apercu-menu="${nom}"]`)
    if (el && el.dataset.valeur !== choix.valeur) {
      el.dataset.valeur = choix.valeur
      el.innerHTML = icone(choix.trace)
    }
    this.barreTarget.querySelectorAll(`[data-menu="${nom}"]`).forEach((b) => {
      b.setAttribute("aria-checked", b.dataset.valeur === choix.valeur)
    })
  }

  // --- Popovers (nuanciers, menus, figures) -------------------------------------

  basculerPopover(conteneur) {
    const panneau = conteneur.querySelector(".rt-tb__popover")
    const ouvrir = panneau.hidden
    this.fermerPopovers()
    if (!ouvrir) return
    panneau.hidden = false
    conteneur.querySelector("[data-ouvrir]").setAttribute("aria-expanded", "true")
    this.selectionAvantPopover = this.editor.state.selection
    document.addEventListener("pointerdown", this.onClicDehors, true)
  }

  fermerPopovers() {
    this.barreTarget.querySelectorAll(".rt-tb__popover").forEach((p) => { p.hidden = true })
    this.barreTarget.querySelectorAll("[data-ouvrir]").forEach((b) => b.setAttribute("aria-expanded", "false"))
    this.barreTarget.querySelector(".rt-figures__erreur").hidden = true
    this.remplacement = null
    this.barreTarget.querySelector(".rt-figures__inserer").textContent = "Insérer"
    document.removeEventListener("pointerdown", this.onClicDehors, true)
  }

  onClicDehors(event) {
    if (!event.target.closest("[data-popover]")) this.fermerPopovers()
  }

  // --- Images ---------------------------------------------------------------------

  choisirFichiers(event) {
    Array.from(event.target.files).forEach((f) => this.envoyerImage(f))
    event.target.value = ""
  }

  fichiersDepuis(transfert) {
    const images = Array.from(transfert?.files || []).filter((f) => /^image\//.test(f.type))
    if (images.length === 0) return false
    images.forEach((f) => this.envoyerImage(f))
    return true
  }

  // Envoi direct à Active Storage, comme Trix le faisait (ActionText) : la
  // pièce jointe reçoit le sgid du blob et l'adresse de redirection.
  envoyerImage(fichier) {
    new DirectUpload(fichier, this.directUploadUrlValue).create((erreur, blob) => {
      if (erreur) return window.alert(`L'image n'a pas pu être envoyée : ${erreur}`)
      const url = this.blobUrlTemplateValue
        .replace(":signed_id", blob.signed_id)
        .replace(":filename", encodeURIComponent(blob.filename))
      const img = new Image()
      img.onload = img.onerror = () => {
        const piece = {
          sgid: blob.attachable_sgid, contentType: blob.content_type, url, filename: blob.filename,
          filesize: blob.byte_size, width: img.naturalWidth || undefined, height: img.naturalHeight || undefined,
          previewable: true
        }
        this.inserer(piece, { presentation: "gallery" })
      }
      img.src = url
    })
  }

  // --- Figures --------------------------------------------------------------------

  insererHorloge() {
    const heure = this.barreTarget.querySelector(".rt-figures__heure").value
    const chiffres = this.barreTarget.querySelector(".rt-figures__chiffres").checked
    this.insererFigure({ kind: "horloge", heure, chiffres }, { remplacement: this.remplacement })
  }

  async insererFigure(params, { remplacement = null } = {}) {
    const reponse = await post("/figures", { body: params, responseKind: "json" })
    if (!reponse.ok) {
      this.barreTarget.querySelector(".rt-figures__erreur").hidden = false
      return
    }
    const piece = await reponse.json

    if (remplacement) {
      // Changer l'heure : la nouvelle horloge prend la place de l'ancienne, à la même taille.
      const ancien = this.editor.state.doc.nodeAt(remplacement.pos)
      this.editor.chain().focus().command(({ tr }) => {
        tr.setNodeMarkup(remplacement.pos, undefined, {
          ...ancien.attrs, attachment: JSON.stringify(piece), contentType: piece.contentType
        })
        return true
      }).run()
    } else {
      if (this.selectionAvantPopover) this.editor.commands.setTextSelection(this.selectionAvantPopover.from)
      const ligne = ["seyes", "ligne", "carreaux"].includes(params.kind)
      // Une ligne d'écriture commence toujours une ligne — sauf juste après une
      // autre ligne d'écriture, qui en finit déjà une : le <br> ajouté là
      // devenait, à l'affichage, une ligne vide entre deux lignes Seyès.
      if (ligne && this.apresDuTexte()) this.editor.commands.setHardBreak()
      this.inserer(piece, params.kind === "horloge" ? { presentation: "taille-25 gauche" } : null)
    }
    // Le menu reste ouvert après une ligne : on en ajoute une autre d'un clic.
    if (params.kind === "horloge") this.fermerPopovers()
    else this.selectionAvantPopover = this.editor.state.selection
  }

  // Le curseur suit-il du texte (et non le début du bloc ou une ligne d'écriture) ?
  apresDuTexte() {
    const $from = this.editor.state.selection.$from
    if ($from.parentOffset === 0) return false
    const avant = $from.nodeBefore
    if (avant?.type.name !== "pieceJointe") return true
    try {
      return !/rt-seyes|rt-ligne/.test(JSON.parse(avant.attrs.attachment).content || "")
    } catch {
      return true
    }
  }

  inserer(piece, attributs) {
    this.editor.chain().focus().insertContent({
      type: "pieceJointe",
      attrs: {
        attachment: JSON.stringify(piece),
        attributes: attributs ? JSON.stringify(attributs) : null,
        contentType: piece.contentType || null
      }
    }).run()
  }

  // « Changer l'heure » dans la barre d'une horloge : le menu s'ouvre prérempli.
  onChangerHeure(event) {
    const { pos, attachment } = event.detail
    const [heure, chiffres] = this.reglagesHorloge(attachment)
    const conteneur = this.barreTarget.querySelector(".rt-figures")
    if (conteneur.querySelector(".rt-tb__popover").hidden) this.basculerPopover(conteneur)
    this.remplacement = { pos }
    this.barreTarget.querySelector(".rt-figures__heure").value = heure
    this.barreTarget.querySelector(".rt-figures__chiffres").checked = chiffres
    this.barreTarget.querySelector(".rt-figures__inserer").textContent = "Changer l'heure"
    this.barreTarget.querySelector(".rt-figures__heure").focus()
  }

  // Réglages d'une horloge, lus dans son sgid : `…/Figure/horloge-0315-chiffres`.
  // Le sgid n'est pas chiffré, seulement signé ; on n'en lit que l'identifiant.
  reglagesHorloge(attachment) {
    try {
      const sgid = JSON.parse(attachment).sgid
      const encode = sgid.slice(0, sgid.lastIndexOf("--")).replace(/-/g, "+").replace(/_/g, "/")
      const match = atob(encode).match(/Figure\/horloge-(\d{2})?(\d{2})?(?:vide)?-(chiffres|nue)/)
      if (!match) return ["", true]
      return [match[1] ? `${parseInt(match[1], 10)}:${match[2]}` : "", match[3] === "chiffres"]
    } catch {
      return ["", true]
    }
  }
}

