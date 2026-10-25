import { Controller } from "@hotwired/stimulus";

// L'erreur d'un champ part dès qu'on y retape : elle parle de la valeur d'avant.
// Le serveur ne la retirerait qu'au prochain envoi, et un champ enregistré en
// direct n'en part qu'en le quittant. Suppose le balisage du wrapper
// `vertical_form` de simple_form.
export default class extends Controller {
  effacer({ target }) {
    target.classList.remove("is-invalid");
    const groupe = target.closest(".form-group");
    groupe.classList.remove("form-group-invalid");
    groupe.querySelector(".invalid-feedback")?.remove();
  }
}
