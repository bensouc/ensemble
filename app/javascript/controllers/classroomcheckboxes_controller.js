import { Controller } from "stimulus"

let checkBoxes
export default class extends Controller {

  static targets = ["boxes"]

  connect() {
    console.log("hello checkox");
  }

  add(event) {
    // console.log(event)
  console.log("click")

    if (event.target.value <= 0) {
      checkBoxes = this
      checkBoxes.boxesTargets.forEach(
        element => {
          console.log(element);
          element.checked = event.target.checked
        }
      )
    }
  };

}
