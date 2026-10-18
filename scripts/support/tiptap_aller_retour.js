// Point d'entrée du banc aller-retour (scripts/tiptap_aller_retour_browser_check.rb) :
// l'éditeur d'énoncé, avec exactement ses extensions et le même passage du HTML
// à l'ouverture et à l'enregistrement (editeur/blocs.js), réduit à « charger puis
// relire ». Ce que l'éditeur ferait d'un énoncé qu'on ouvre et réenregistre.
import { Editor } from "@tiptap/core"
import { extensionsDeLEditeur } from "../../app/javascript/editeur/extensions"
import { pourLEditeur, pourLEnregistrement, estUnAncienEnonce } from "../../app/javascript/editeur/blocs"

// Un éditeur par mise en page, choisi comme le fait editeur_enonce_controller.
const editeur = (ancien) => new Editor({ element: document.createElement("div"), extensions: extensionsDeLEditeur({ ancien }) })
const editeurs = { ancien: editeur(true), nouveau: editeur(false) }

window.allerRetour = function (html) {
  const editor = estUnAncienEnonce(html) ? editeurs.ancien : editeurs.nouveau
  editor.commands.setContent(pourLEditeur(html), { emitUpdate: false })
  return pourLEnregistrement(editor.getHTML())
}
window.bancPret = true
