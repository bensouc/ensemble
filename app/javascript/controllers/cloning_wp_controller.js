import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['cloningpanel','wp'];

  // connect() {
  //   console.log('controller cloning is connected');
  // }

  displayCloningForm() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
    this.cloningpanelTarget.classList.toggle('d-none');
    this.wpTarget.classList.toggle('blurred');

  }
}
