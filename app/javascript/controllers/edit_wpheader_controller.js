import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['infos', 'form'];
  connect() {
    console.log('WP-edit connected');
  }

  displayForm() {
    this.buttonTarget.classList.add('d-none');
    this.formTarget.classList.remove('d-none');
  }
}
