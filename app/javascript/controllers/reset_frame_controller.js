import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    name: String
  }

  connect() {
    console.log(`reset frame ${this.nameValue}connected`);
  }

  resetFrame(){
    console.log("Reset");
    const frame = document.getElementById(this.nameValue)
    frame.innerHTML = ""
  }

}
