import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['beltBtn']

  connect() {

    console.log('sysplay belt connected')

  }
  displayBtn() {
    this.beltBtnTargets.forEach(btn => {
      btn.classList.toggle('d-none');
    })
  }
  hideBtn() {
    this.beltBtnTargets.forEach(btn => {
      btn.classList.add('d-none');
    })
  }
  // data-action="mouseover->wps-result#displayBtn mouseout->wps-result#hideBtn"
}
