import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['spinner']
  connect() {
    // console.log("spinner OK")
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove('d-none')
      this.spinnerTarget.classList.add('d-none')
    }
  }

  displaySpinner(event) {
    const content = `<div class="lds-background" data-loadingspinnermgnt-target='spinner'>
  <div class="lds-default">
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
  </div>
</div>`;
    this.element.insertAdjacentHTML('afterbegin', content)
  }

  // insert spinner
  addSpinner(event) {
    // event.preventDefault()
    // `currentTarget` et pas `target` : le bouton porte une icône et un libellé,
    // un clic sur l'un d'eux visait l'enfant et le spinner remplaçait l'icône.
    const target = event.currentTarget
    const width = target.offsetWidth
    const height = target.offsetHeight
    target.style.height = `${height}px`
    target.style.width = `${width}px`
    target.innerHTML = `
      <div class="rotating" >
        <i class="fa-solid fa-gear"></i>
      </div>
      `
  };

  // Posé sur un formulaire, en `submit` et non en `click` : un formulaire que le
  // navigateur refuse (champ requis vide) ne part pas, et le rouage ne doit pas
  // tourner pour rien. Le bouton qui l'envoie (`event.submitter`) prend le
  // rouage. Un second envoi pendant que le serveur travaille est ignoré : il
  // créerait un second plan.
  tournerPendantEnvoi(event) {
    if (this.element.dataset.envoiEnCours) {
      event.preventDefault()
      return
    }
    this.element.dataset.envoiEnCours = "true"

    const bouton = event.submitter
    if (!bouton) return
    bouton.dataset.contenuInitial = bouton.innerHTML
    bouton.style.width = `${bouton.offsetWidth}px`
    bouton.style.height = `${bouton.offsetHeight}px`
    bouton.innerHTML = `<div class="rotating"><i class="fa-solid fa-gear"></i></div>`
  }

  // Le retour arrière ressert la page depuis le cache du navigateur, rouage
  // compris : sans ça, le bouton tournerait encore et n'enverrait plus rien.
  reinitialiserAuRetour(event) {
    if (!event.persisted) return

    delete this.element.dataset.envoiEnCours
    this.element.querySelectorAll("[data-contenu-initial]").forEach((bouton) => {
      bouton.innerHTML = bouton.dataset.contenuInitial
      bouton.style.width = ""
      bouton.style.height = ""
      delete bouton.dataset.contenuInitial
    })
  }
}
