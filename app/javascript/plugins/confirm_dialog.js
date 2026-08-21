import { Turbo } from "@hotwired/turbo-rails"
import Rails from "@rails/ujs"
import Swal from "sweetalert2"

// Les confirmations passaient par `window.confirm` : une boîte native, en bleu
// système, qu'aucun CSS n'atteint. On la remplace par la palette de l'app.
//
// Deux mécanismes coexistent dans les vues et il faut brancher les deux :
//   - Turbo pour les `button_to` (vrais formulaires) et les liens `turbo_method` ;
//   - @rails/ujs pour les liens `method: :delete` avec `data-confirm`.
// Migrer les seconds vers Turbo aurait changé le mécanisme de requêtes de
// suppressions destructrices (classe, élève, conversation) : on préfère habiller les
// deux chemins que déplacer le risque.
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

Turbo.setConfirmMethod(askConfirmation)

// UJS exige une réponse synchrone : on refuse le clic, puis on le rejoue sans
// l'attribut si l'utilisateur confirme. L'attribut est aussitôt remis, sinon un
// second clic (action en échec, élément non remplacé) ne demanderait plus rien.
Rails.confirm = (message, element) => {
  askConfirmation(message).then((confirmed) => {
    if (!confirmed) return

    element.removeAttribute("data-confirm")
    element.click()
    element.setAttribute("data-confirm", message)
  })

  return false
}
