import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['menu']
  connect() {
    // this.setUpSkillsDisplay()
    console.log("dropdown connected");
  }

  toggle(){
    console.log(this.menuTarget)
    this.element.classList.toggle('trix-active')
    this.menuTarget.classList.toggle('hidden')
  }

  hide(){
    console.log('hide')
    this.menuTarget.classList.add('hidden')
  }
}
