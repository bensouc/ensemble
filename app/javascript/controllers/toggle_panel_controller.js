import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['panel'];
  connect() {
    console.log('toogle panel controller connected');
  }

  displayPanel() {
    // console.log('display toggle BMO');
        this.panelTarget.classList.toggle('d-none');
  }
}
