import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['formBox','form', "button"];

  connect() {
    console.log('createskillconnected');
  }

  displayForm() {
    this.formBoxTarget.classList.toggle('d-none');
    this.buttonTarget.classList.toggle('d-none');
    this.formTarget.reset();
  }
  hideForm() {
    this.formBoxTarget.classList.toggle('d-none');
    this.buttonTarget.classList.toggle('d-none');
  }
}
