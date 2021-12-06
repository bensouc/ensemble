import { Controller } from "stimulus"

export default class extends Controller {

  static targets = ["seetext","createtext"]

  // connect() {
  //   console.log(this.seetextTarget);
  // }
  seechange(event) {

    this.seetextTarget.classList.toggle('active');
    this.createtextTarget.classList.toggle('active');
   }
}
