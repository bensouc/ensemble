import { Controller } from "stimulus";

export default class extends Controller {

  connect() {
    console.log('submitonchange OK connected');
  }
  submitForm(event){
    const form = document.getElementById('domainForm')
    // console.log(event.target.parentElement.parentElement.parentElement.parentElement)
    form.submit()
  }
}
