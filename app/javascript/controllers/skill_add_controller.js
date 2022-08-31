import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['button', 'form'];
  connect(){
    console.log('skill-add connected');
  }

  displayForm() {
    this.buttonTarget.classList.toggle('d-none');
    this.formTarget.classList.toggle('d-none');
  }
}
