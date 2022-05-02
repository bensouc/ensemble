import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['start', 'end'];

  connect() {
    console.log('**********')
    console.log(this.startTarget)
  }

  add(event) {
    console.log('**********')
    console.log(this.startTarget)
  }
}
