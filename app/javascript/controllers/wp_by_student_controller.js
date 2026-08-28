import { Controller } from "@hotwired/stimulus";
import Swal from 'sweetalert2'
export default class extends Controller {
  static targets = ['count', 'wplist', 'folderopen', 'folderclosed', 'wpLine'];
  static values = { ouvert: Boolean };

  // Revenir d'une évaluation doit ramener là où on était : la liste de l'élève
  // se rouvre, et l'écran redescend dessus. Sans cela on retombait en haut
  // d'une page toute repliée, à chercher l'élève qu'on venait de quitter.
  connect() {
    if (!this.ouvertValue) return;

    this.displayList();
    this.element.scrollIntoView({ block: 'center' });
  }

  displayList() {
    this.folderopenTarget.classList.toggle('d-none');
    this.folderclosedTarget.classList.toggle('d-none');
    this.wplistTarget.classList.toggle('d-none');

  }

  // CTA « Ajouter » d'une compétence : le formulaire de création vit en bas de la
  // liste, il faut donc la déplier avant de s'y rendre. On ne fait qu'ouvrir —
  // jamais refermer — pour ne pas masquer le formulaire qu'on vient d'appeler.
  openList() {
    if (this.wplistTarget.classList.contains('d-none')) {
      this.displayList()
    }
    const frame = this.element.querySelector('turbo-frame[id$="_new_challenge"]')
    if (!frame) return
    // Le formulaire arrive de façon asynchrone : on attend son rendu pour
    // descendre dessus, sinon on visait une frame encore vide.
    frame.addEventListener(
      'turbo:frame-load',
      () => frame.scrollIntoView({ behavior: 'smooth', block: 'center' }),
      { once: true }
    )
  }

  deleteWorkPlan(event) {

    event.preventDefault()
    event.stopImmediatePropagation()
    Swal.fire({
      title: 'Voulez vous Supprimer Ce Plan de Travail?',
      showDenyButton: true,
      // showCancelButton: true,
      confirmButtonText: 'Oui',
      denyButtonText: `Non`,
    }).then((result) => {
      /* Read more about isConfirmed, isDenied below */
      if (result.isConfirmed) {
        // console.log(event.target.parentElement.parentElement.parentElement.action)
        this.request = new Request(event.target.parentElement.parentElement.parentElement.action, {
          method: 'DELETE',
          credentials: "include",
          headers: {
            "X-CSRF-Token": document.querySelector(
              'meta[name="csrf-token"]'
            ).content
          }
        });
        // console.log(this.request)
        this.removeWorkPlanContent(this.request)
        this.updateNbWp()
      } else if (result.isDenied) {
        // Swal.fire('Changes are not saved', '', 'info')
      }
    })


  }

  removeWorkPlanContent(request) {
    console.log(request)
    fetch(request)
      .then((response) => {
        if (response.status == 200) {
          this.wpLineTarget.remove();
        } else {
          console.log("Raté le delete")
        }
      })
  }

  updateNbWp() {
    const count = this.wpLineTargets.length
    // console.log(this.countTarget.innerHTML)
    // Même format que `Mobile::WorkPlansHelper#plans_label`, sinon le compte
    // change de forme dès qu'on supprime un plan.
    const restants = count - 1
    this.countTarget.innerHTML = `${restants} plan${restants > 1 ? "s" : ""}`
  }

}
