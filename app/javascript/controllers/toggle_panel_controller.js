import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['panel','btn'];
  connect() {
    console.log('toogle panel controller connected');
  }

  displayPanel() {
    // console.log('display toggle BMO');
        this.panelTarget.classList.toggle('d-none');
        this.btnTarget.classList.toggle('d-none')
  }
}
