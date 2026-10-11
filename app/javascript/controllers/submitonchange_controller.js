import { Controller } from "@hotwired/stimulus";

export default class extends Controller {

  connect() {
    // console.log('submitonchange OK connected');
  }
  submitForm(event){
    const form = document.getElementById('domainForm')
    // console.log(event.target.parentElement.parentElement.parentElement.parentElement)
    const list = document.getElementById("skills-challenge-list")
    list.innerHTML = '<div class="spinner-border --rose  " role="status"></div >'
    // La liste des exercices de ceinture suit le même filtre : vidée aussi,
    // plutôt que de rester affichée pour l'ancienne ceinture pendant le chargement.
    const beltList = document.getElementById("skills-belt-challenge-list")
    if (beltList) beltList.innerHTML = ""
    form.submit()
  }
}
