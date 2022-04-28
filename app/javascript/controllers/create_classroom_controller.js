import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['form'];

  connect() {
    console.log('createclassroomconnected');
  }

  displayForm() {
    this.formTarget.classList.toggle('d-none');
  }
}
