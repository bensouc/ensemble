import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["show", "delete"]
  connect() {
    // console.log("special wps controller OK")
  }

  displayWps() {
    if (this.hasShowTarget) {this.showTarget.classList.add('d-none')}
    this.deleteTarget.classList.remove('d-none')
  }
  hideWps() {
    if (this.hasShowTarget) {this.showTarget.classList.remove('d-none')}
    this.deleteTarget.classList.add('d-none')
  }
}
