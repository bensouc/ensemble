import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['wplist'];
  connect() {
    console.log('wp-by-student');
  }

  displayList() {

    this.wplistTarget.classList.toggle('d-none');
  }
}
