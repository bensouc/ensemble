import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['button','name'];
  connect() {
    console.log('WPS edit connected');
  }

  displayName() {
    // console.log(this.nameTarget);
    this.nameTarget.classList.toggle('d-none');
      }

  hideName() {
    this.nameTarget.classList.add('d-none');
  }
}
