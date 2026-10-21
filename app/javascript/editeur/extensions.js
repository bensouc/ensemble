// Extensions TipTap de l'éditeur d'énoncé.
//
// Partagées par l'éditeur (editeur_enonce_controller) et par le banc
// aller-retour (scripts/tiptap_aller_retour_browser_check.rb) : le banc éprouve
// exactement la configuration que les professeur·es utilisent.
//
// Chaque réglage ci-dessous a été imposé par un énoncé réel : sans lui, le banc
// trouvait des énoncés abîmés par un simple ouvrir-enregistrer.
import { Extension, mergeAttributes } from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import Paragraph from "@tiptap/extension-paragraph"
import { ListItem } from "@tiptap/extension-list"
import { TextStyle, FontSize } from "@tiptap/extension-text-style"
import { Color } from "@tiptap/extension-color"
import TextAlign from "@tiptap/extension-text-align"
import { TableKit, TableView } from "@tiptap/extension-table"
import { Placeholder } from "@tiptap/extensions"
import { Plugin, TextSelection } from "@tiptap/pm/state"
import { Decoration, DecorationSet } from "@tiptap/pm/view"
import { PieceJointe } from "./piece_jointe"
import { ZONE_TYPE } from "./types"
import { Colonnes, Colonne } from "./colonnes"

// Les blocs de Trix sont des <div>. Un paragraphe TipTap s'écrit <p> ; or le
// HTML interdit un <figure> (pièce jointe) dans un <p> : relu par Rails, le <p>
// se coupait en deux paragraphes vides et la pièce jointe se retrouvait dehors.
//
// La classe `rt-p` signe un paragraphe de cet éditeur : lui seul prend
// l'interligne 1,4 et se colle au suivant (trix/_content.scss). Un énoncé plus
// ancien, sans paragraphe signé (`estUnAncienEnonce`), s'édite sans signer
// (`signe: false`) : il garde son interligne 1,6 et ses espaces, à l'ouverture
// comme à l'enregistrement — son affichage et son PDF ne bougent pas.
const Paragraphe = Paragraph.extend({
  addOptions() {
    return { ...this.parent?.(), signe: true }
  },

  parseHTML() {
    return [
      // Des énoncés anciens sont enregistrés dans l'enveloppe de rendu
      // d'ActionText : on en lit le contenu sans en faire un paragraphe.
      { tag: "div.trix-content", skip: true, priority: 60 },
      { tag: "p" },
      { tag: "div" }
    ]
  },
  renderHTML({ HTMLAttributes }) {
    return ["div", this.options.signe ? mergeAttributes(HTMLAttributes, { class: "rt-p" }) : HTMLAttributes, 0]
  }
})

// Trix met des titres et des blocs de code dans des puces.
const Puce = ListItem.extend({ content: "block+" })

// Couleurs posées sur <strong>, <em>, <b>, <i> (texte collé d'ailleurs) :
// TextStyle ne les lisait que sur un <span>. `consuming: false` laisse le gras
// et l'italique être lus aussi.
const StyleTexte = TextStyle.extend({
  parseHTML() {
    const avecStyle = (tag) => ({
      tag: `${tag}[style]`,
      consuming: false,
      getAttrs: (el) => (/color|background/.test(el.getAttribute("style")) ? {} : false)
    })
    return [...(this.parent?.() || []), avecStyle("strong"), avecStyle("em"), avecStyle("b"), avecStyle("i")]
  }
})

// Surlignage : `background-color` sur un span, comme Trix l'écrit.
const Surlignage = Extension.create({
  name: "surlignage",
  addGlobalAttributes() {
    return [{
      types: ["textStyle"],
      attributes: {
        backgroundColor: {
          default: null,
          parseHTML: (el) => el.style.backgroundColor || null,
          renderHTML: (a) => (a.backgroundColor ? { style: `background-color: ${a.backgroundColor}` } : {})
        }
      }
    }]
  }
})

// Interligne de bloc (menu « Interligne » de la barre).
const Interligne = Extension.create({
  name: "interligne",
  addGlobalAttributes() {
    return [{
      types: ["paragraph", "heading"],
      attributes: {
        lineHeight: {
          default: null,
          parseHTML: (el) => el.style.lineHeight || null,
          renderHTML: (a) => (a.lineHeight ? { style: `line-height: ${a.lineHeight}` } : {})
        }
      }
    }]
  }
})

// Bordures d'un tableau (bouton « Bordures » de la barre du tableau) : masquées,
// le tableau porte `rt-table--sans-bordure` (trix/_tables.scss).
const Bordures = Extension.create({
  name: "bordures",
  addGlobalAttributes() {
    return [{
      types: ["table"],
      attributes: {
        bordures: {
          default: true,
          parseHTML: (el) => !el.classList.contains("rt-table--sans-bordure"),
          renderHTML: (a) => (a.bordures === false ? { class: "rt-table--sans-bordure" } : {})
        }
      }
    }]
  }
})

// Un tableau redimensionnable s'affiche par la vue de TipTap, qui dessine un
// <table> nu : celle-ci lui remet les classes de l'éditeur — la grille et, s'il
// y a lieu, l'absence de bordures.
class VueTableau extends TableView {
  constructor(node, cellMinWidth) {
    super(node, cellMinWidth)
    this.classer(node)
  }

  update(node) {
    const accepte = super.update(node)
    if (accepte) this.classer(node)
    return accepte
  }

  classer(node) {
    this.table.className = node.attrs.bordures === false ? "rt-table__grid rt-table--sans-bordure" : "rt-table__grid"
  }
}

// Une ligne sous un tableau, des colonnes ou une zone de manipulation qui finissent l'énoncé : sans elle,
// on ne pouvait plus écrire dessous (seul un clic dans une bande étroite y
// posait un curseur presque invisible, et sous des colonnes la saisie partait
// dans la dernière colonne). Vide, elle n'est pas enregistrée (editeur/blocs.js).
// Hors de l'historique : « Annuler » ne la retire pas.
const BLOCS_SANS_LIGNE_DESSOUS = ["table", "colonnes"]
// Une zone de manipulation, seule dans son paragraphe, fait bloc elle aussi.
const estUneZone = (node) => node?.type.name === "pieceJointe" && node.attrs.contentType === ZONE_TYPE
const estUnBloc = (node) =>
  BLOCS_SANS_LIGNE_DESSOUS.includes(node?.type.name) ||
  (node?.type.name === "paragraph" && node.childCount === 1 && estUneZone(node.firstChild))
const finitParUnBloc = (doc) => estUnBloc(doc.lastChild)
// La ligne est là, vide, sous le bloc final.
const aSaLigneVide = (doc) =>
  doc.childCount > 1 && doc.lastChild.type.name === "paragraph" && !doc.lastChild.content.size &&
  estUnBloc(doc.child(doc.childCount - 2))

const LigneSousLeBloc = Extension.create({
  name: "ligneSousLeBloc",
  addProseMirrorPlugins() {
    return [new Plugin({
      appendTransaction: (_transactions, _avant, state) => {
        if (!finitParUnBloc(state.doc)) return null
        return state.tr.insert(state.doc.content.size, state.schema.nodes.paragraph.create())
          .setMeta("addToHistory", false)
      },
      // Vide, la ligne est repliée hors du curseur (LigneDuCurseur) et ne se
      // vise plus : un clic sous le bloc final, dans le cadre de l'éditeur, y
      // pose le curseur. Avant ProseMirror (capture), qui viserait le bloc.
      view: (view) => {
        const cadre = view.dom.parentElement
        const surAppui = (event) => {
          if (event.target !== cadre && !view.dom.contains(event.target)) return
          const { doc } = view.state
          const bloc = view.dom.lastElementChild?.previousElementSibling
          if (!aSaLigneVide(doc) || !bloc || event.clientY <= bloc.getBoundingClientRect().bottom) return
          event.preventDefault()
          event.stopPropagation()
          view.dispatch(view.state.tr.setSelection(TextSelection.create(doc, doc.content.size - 1)))
          view.focus()
        }
        cadre.addEventListener("mousedown", surAppui, true)
        return { destroy: () => cadre.removeEventListener("mousedown", surAppui, true) }
      }
    })]
  },
  // Dès l'ouverture, et pas seulement à la première frappe.
  onCreate() {
    this.editor.view.dispatch(this.editor.state.tr)
  }
})

// La ligne du curseur : le paragraphe où il est, ou celui de la pièce choisie.
// Les lignes que l'éditeur ajoute pour y poser le curseur — autour d'une image
// ou d'une zone, sous un bloc qui finit l'énoncé — n'existent ni à l'affichage
// ni au PDF : elles ne se montrent que là (trix/_tiptap.scss).
const LigneDuCurseur = Extension.create({
  name: "ligneDuCurseur",
  addProseMirrorPlugins() {
    return [new Plugin({
      props: {
        decorations: ({ doc, selection }) => {
          const { $from } = selection
          if (!$from.depth || !$from.parent.isTextblock) return null
          const debut = $from.before()
          return DecorationSet.create(doc, [Decoration.node(debut, debut + $from.parent.nodeSize, { class: "rt-p--curseur" })])
        }
      }
    })]
  }
})

export function extensionsDeLEditeur({ placeholder = "", ancien = false } = {}) {
  return [
    StarterKit.configure({
      heading: { levels: [1, 2, 3] },
      paragraph: false,
      listItem: false,
      // Ajoutait un paragraphe vide après un titre ou une pièce jointe finale.
      trailingNode: false,
      link: { openOnClick: false, autolink: true }
    }),
    Paragraphe.configure({ signe: !ancien }),
    Puce,
    StyleTexte,
    Color,
    Surlignage,
    // Taille du texte, en `em` : même proportion à l'écran (17 px) et au PDF (20 px).
    FontSize,
    Interligne,
    TextAlign.configure({ types: ["heading", "paragraph"] }),
    // Mêmes classes que les tableaux maison : même allure à l'écran et au PDF.
    TableKit.configure({
      // Colonnes à élargir en tirant leur bord ; les largeurs, en pixels dans
      // l'éditeur, s'enregistrent en proportions (editeur/blocs.js).
      table: { resizable: true, View: VueTableau, cellMinWidth: 40, HTMLAttributes: { class: "rt-table__grid" } },
      tableCell: { HTMLAttributes: { class: "rt-cell" } },
      tableHeader: { HTMLAttributes: { class: "rt-cell" } }
    }),
    PieceJointe,
    Colonnes,
    Colonne,
    LigneSousLeBloc,
    LigneDuCurseur,
    Bordures,
    Placeholder.configure({ placeholder })
  ]
}
