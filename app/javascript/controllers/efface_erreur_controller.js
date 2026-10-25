import { Controller } from "@hotwired/stimulus";

// Efface l'erreur d'un champ dès qu'on y retape.
//
// L'erreur vient du serveur et restait sous le champ jusqu'au prochain envoi.
// Sur « Mon compte », le profil s'enregistre en direct et la réponse ne
// redessine que les avatars : « Prénom doit être rempli(e) » restait affiché
// sous un prénom déjà corrigé, et même enregistré.
export default class extends Controller {
  effacer(event) {
    const champ = event.target;
    if (!champ.classList.contains("is-invalid")) return;

    champ.classList.remove("is-invalid");
    const groupe = champ.closest(".form-group");
    groupe?.classList.remove("form-group-invalid");
    groupe?.querySelector(".invalid-feedback")?.remove();
  }
}
