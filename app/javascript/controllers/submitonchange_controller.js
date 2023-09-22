import { Controller } from "stimulus";

export default class extends Controller {

  connect() {
    console.log('submitonchange OK connected');
  }
  submitForm(event){
    const form = document.getElementById('domainForm')
    // console.log(event.target.parentElement.parentElement.parentElement.parentElement)
    const list = document.getElementById("skills-challenge-list")
    list.innerHTML = '<div class="spinner-border --rose  " role="status"></div >'
    form.submit()
  }
}
