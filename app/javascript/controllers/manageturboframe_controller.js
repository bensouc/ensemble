import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    id: Number
  }
  connect() {
    // console.log('managetruborgrame OK connected');

  }

  cleanTurboFrame() {
    const turboFrame = document.getElementById(`skill_${this.idValue}_new_challenge`)

    turboFrame.innerHTML = ""
  }

}
