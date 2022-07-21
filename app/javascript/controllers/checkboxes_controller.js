import { Controller } from "stimulus"

export default class extends Controller {

  static targets = ["boxes"]

  connect() {
    console.log("checkboxes controller is connected");
  }

  add(event) {
    // console.log(event.target.value)
    // // console.log("prout")
    // // this.seetextTarget.classList.toggle('active');
    // // this.createtextTarget.classList.toggle('active');
    if (event.target.value == 0) {
      this.boxesTargets.forEach(
        element => {
          console.log(element);
          element.checked = event.target.checked
        }
      )
    }
  };

}
