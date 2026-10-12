// Point d'entrée du banc aller-retour (scripts/tiptap_aller_retour_browser_check.rb) :
// l'éditeur d'énoncé, avec exactement ses extensions, réduit à « charger puis
// relire ». Ce que l'éditeur ferait d'un énoncé qu'on ouvre et réenregistre.
import { Editor } from "@tiptap/core"
import { extensionsDeLEditeur } from "../../app/javascript/editeur/extensions"

const editor = new Editor({ element: document.createElement("div"), extensions: extensionsDeLEditeur() })

window.allerRetour = function (html) {
  editor.commands.setContent(html, { emitUpdate: false })
  return editor.getHTML()
}
window.bancPret = true
