import { Turbo } from "@hotwired/turbo-rails"
import Swal from "sweetalert2"

// Les confirmations passaient par `window.confirm` : une boîte native, en bleu
// système, qu'aucun CSS n'atteint. On la remplace par la palette de l'app.
//
// Turbo est seul à les demander : `data-turbo-confirm`, sur un `button_to`, un
// bouton de formulaire ou un lien `turbo_method`. Un `data-confirm` (rails-ujs,
// retiré) ne demanderait plus rien.
const ROSE = "#F24150"
const GRIS = "#9C9C9C"

function escapeHtml(text) {
  return String(text).replace(/[&<>"']/g, (char) => (
    { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char]
  ))
}

// `focusCancel` : ces boîtes gardent presque toutes une suppression derrière elles,
// la touche Entrée ne doit pas la déclencher.
export function askConfirmation(message) {
  return Swal.fire({
    icon: "warning",
    iconColor: ROSE,
    html: escapeHtml(message).replace(/\n/g, "<br>"),
    showCancelButton: true,
    confirmButtonText: "Confirmer",
    cancelButtonText: "Annuler",
    confirmButtonColor: ROSE,
    cancelButtonColor: GRIS,
    reverseButtons: true,
    focusCancel: true
  }).then((result) => result.isConfirmed)
}

// `Turbo.setConfirmMethod`, déprécié en Turbo 8, n'était plus qu'un relais vers ce réglage.
Turbo.config.forms.confirm = askConfirmation
