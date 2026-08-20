import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['spinner']
  connect() {
    // console.log("spinner OK")
    if (this.hasSpinnerTarget) {
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
    // `currentTarget` et pas `target` : le bouton porte une icône et un libellé,
    // un clic sur l'un d'eux visait l'enfant et le spinner remplaçait l'icône.
    const target = event.currentTarget
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
