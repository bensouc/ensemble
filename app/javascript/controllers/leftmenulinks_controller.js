import { Controller } from "stimulus"

export default class extends Controller {

  static targets = ["btn", "links"]

  connect() {
    console.log('links controller connected');
  }
  toggleDisplayLinks() {
    this.linksTarget.classList.toggle('d-none');
  }
}
