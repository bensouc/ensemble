import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['button', 'form'];
  connect() {
    console.log('WP-edit connected');
  }

  displayForm() {
    console.log('display toggle BMO');
    this.buttonTarget.classList.add('d-none');
    this.formTarget.classList.remove('d-none');
  }
}
