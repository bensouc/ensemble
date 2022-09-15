import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['form', "button"];

  connect() {
    // console.log('createclassroomconnected');
  }

  displayForm() {
    this.formTarget.classList.toggle('d-none');
    this.buttonTarget.classList.toggle('d-none');
  }
}
