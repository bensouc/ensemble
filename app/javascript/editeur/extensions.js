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
import { TableKit } from "@tiptap/extension-table"
import { Placeholder } from "@tiptap/extensions"
import { Plugin } from "@tiptap/pm/state"
import { PieceJointe } from "./piece_jointe"
import { Colonnes, Colonne } from "./colonnes"

// Les blocs de Trix sont des <div>. Un paragraphe TipTap s'écrit <p> ; or le
// HTML interdit un <figure> (pièce jointe) dans un <p> : relu par Rails, le <p>
// se coupait en deux paragraphes vides et la pièce jointe se retrouvait dehors.
//
// La classe `rt-p` signe un paragraphe enregistré par cet éditeur : lui seul
// prend l'interligne 1,4 et se colle au suivant (trix/_content.scss). Un énoncé
// plus ancien garde sa mise en page tant qu'on ne le rouvre pas.
const Paragraphe = Paragraph.extend({
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
    return ["div", mergeAttributes(HTMLAttributes, { class: "rt-p" }), 0]
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

// Une ligne sous un tableau ou des colonnes qui finissent l'énoncé : sans elle,
// on ne pouvait plus écrire dessous (seul un clic dans une bande étroite y
// posait un curseur presque invisible, et sous des colonnes la saisie partait
// dans la dernière colonne). Vide, elle n'est pas enregistrée (editeur/blocs.js).
// Hors de l'historique : « Annuler » ne la retire pas.
const BLOCS_SANS_LIGNE_DESSOUS = ["table", "colonnes"]

const LigneSousLeBloc = Extension.create({
  name: "ligneSousLeBloc",
  addProseMirrorPlugins() {
    return [new Plugin({
      appendTransaction: (_transactions, _avant, state) => {
        if (!BLOCS_SANS_LIGNE_DESSOUS.includes(state.doc.lastChild?.type.name)) return null
        return state.tr.insert(state.doc.content.size, state.schema.nodes.paragraph.create())
          .setMeta("addToHistory", false)
      }
    })]
  },
  // Dès l'ouverture, et pas seulement à la première frappe.
  onCreate() {
    this.editor.view.dispatch(this.editor.state.tr)
  }
})

export function extensionsDeLEditeur({ placeholder = "" } = {}) {
  return [
    StarterKit.configure({
      heading: { levels: [1, 2, 3] },
      paragraph: false,
      listItem: false,
      // Ajoutait un paragraphe vide après un titre ou une pièce jointe finale.
      trailingNode: false,
      link: { openOnClick: false, autolink: true }
    }),
    Paragraphe,
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
      table: { resizable: false, HTMLAttributes: { class: "rt-table__grid" } },
      tableCell: { HTMLAttributes: { class: "rt-cell" } },
      tableHeader: { HTMLAttributes: { class: "rt-cell" } }
    }),
    PieceJointe,
    Colonnes,
    Colonne,
    LigneSousLeBloc,
    Placeholder.configure({ placeholder })
  ]
}
