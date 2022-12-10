import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['spinner']
  connect() {
    if (this.spinnerTarget) {
      this.spinnerTarget.classList.remove('d-none')
      this.spinnerTarget.classList.add('d-none')
    }
  }

  displaySpinner(event) {
    const content = `<div class="lds-background" data-loadingspinnermgnt-target='spinner'>
  <div class="lds-default">
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
    <div></div>
  </div>
</div>`;
    this.element.insertAdjacentHTML('afterbegin', content)
  }
}
