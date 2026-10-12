// Colonnes : un bloc à deux ou trois colonnes, chacune avec son propre contenu
// (texte, images, figures, tableaux). On choisit ce qui va dans chaque colonne,
// contrairement aux colonnes « journal » où le texte passe seul de l'une à l'autre.
//
// Enregistré comme <div class="rt-colonnes rt-colonnes--2"><div class="rt-colonne">…
// La mise en page vient de la feuille de style (trix/_colonnes.scss) : le
// sanitizer d'ActionText retire `grid-template-columns` ou `column-count` d'un
// style, mais garde les classes.
import { Node, mergeAttributes } from "@tiptap/core"
import { TextSelection } from "@tiptap/pm/state"

export const Colonne = Node.create({
  name: "colonne",
  content: "block+",
  isolating: true,
  defining: true,

  parseHTML() {
    // Avant la règle `div` du paragraphe (priorité 50).
    return [{ tag: "div.rt-colonne", priority: 70 }]
  },

  renderHTML({ HTMLAttributes }) {
    return ["div", mergeAttributes(HTMLAttributes, { class: "rt-colonne" }), 0]
  }
})

export const Colonnes = Node.create({
  name: "colonnes",
  group: "block",
  content: "colonne{2,3}",
  isolating: true,
  defining: true,

  addAttributes() {
    return {
      nombre: {
        default: 2,
        parseHTML: (el) => (el.classList.contains("rt-colonnes--3") ? 3 : 2),
        renderHTML: () => ({})
      }
    }
  },

  parseHTML() {
    return [{ tag: "div.rt-colonnes", priority: 70 }]
  },

  renderHTML({ node }) {
    return ["div", { class: `rt-colonnes rt-colonnes--${node.childCount}` }, 0]
  },

  addCommands() {
    return {
      // Un bloc de colonnes vides, après le bloc où est le curseur (à sa place
      // s'il est vide) ; le curseur va dans la première colonne.
      insererColonnes: (nombre = 2) => ({ state, tr, dispatch }) => {
        const { schema } = state
        const colonnes = this.type.create(null, Array.from({ length: nombre }, () =>
          schema.nodes.colonne.create(null, schema.nodes.paragraph.create())))
        if (!dispatch) return true

        const $from = tr.selection.$from
        const bloc = $from.node(1)
        let debut
        if (bloc && bloc.isTextblock && bloc.content.size === 0) {
          debut = $from.before(1)
          tr.replaceWith(debut, $from.after(1), colonnes)
        } else {
          debut = bloc ? $from.after(1) : $from.pos
          tr.insert(debut, colonnes)
        }
        // colonnes > colonne > paragraphe : trois ouvertures avant le texte.
        tr.setSelection(TextSelection.create(tr.doc, debut + 3)).scrollIntoView()
        return true
      },

      // Retire les colonnes autour du curseur : leurs contenus se suivent, de
      // gauche à droite, sans rien perdre.
      retirerColonnes: () => ({ state, tr, dispatch }) => {
        const $from = state.selection.$from
        for (let d = $from.depth; d > 0; d--) {
          const noeud = $from.node(d)
          if (noeud.type.name !== this.name) continue
          if (dispatch) {
            const blocs = []
            noeud.forEach((colonne) => colonne.forEach((bloc) => blocs.push(bloc)))
            tr.replaceWith($from.before(d), $from.after(d), blocs)
          }
          return true
        }
        return false
      }
    }
  }
})
