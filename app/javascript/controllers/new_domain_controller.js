import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['button', 'domainform'];
  connect() {
    console.log('add-domain connected');
  }

  displayForm() {
    this.buttonTarget.classList.toggle('d-none');
    this.domainformTarget.classList.toggle('d-none');
    window.scrollTo(0, document.body.scrollHeight);
  }

}
