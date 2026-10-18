// Point d'entrée du banc aller-retour (scripts/tiptap_aller_retour_browser_check.rb) :
// l'éditeur d'énoncé, avec exactement ses extensions et le même passage du HTML
// à l'ouverture et à l'enregistrement (editeur/blocs.js), réduit à « charger puis
// relire ». Ce que l'éditeur ferait d'un énoncé qu'on ouvre et réenregistre.
import { Editor } from "@tiptap/core"
import { extensionsDeLEditeur } from "../../app/javascript/editeur/extensions"
import { pourLEditeur, pourLEnregistrement } from "../../app/javascript/editeur/blocs"

const editor = new Editor({ element: document.createElement("div"), extensions: extensionsDeLEditeur() })

window.allerRetour = function (html) {
  editor.commands.setContent(pourLEditeur(html), { emitUpdate: false })
  return pourLEnregistrement(editor.getHTML())
}
window.bancPret = true
