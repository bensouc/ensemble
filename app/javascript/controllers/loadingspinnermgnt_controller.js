import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['spinner']
  connect() {
    // console.log("spinner OK")
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

  // insert spinner
  addSpinner(event) {
    // event.preventDefault()
    const target = event.target
    const width = target.offsetWidth
    const height = target.offsetHeight
    target.style.height = `${height}px`
    target.style.width = `${width}px`
    target.innerHTML = `
      <div class="rotating" >
        <i class="fa-solid fa-gear"></i>
      </div>
      `
  };
}
