//open_modal_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    // console.log('modal open connetec')
  }
  emptyModal() {
    const modal = document.querySelector('.modal-ensemble')
    modal.classList.add('d-none')
  }

  addSpinner(event) {
    const target = event.target
    const width = target.offsetWidth
    target.style.width = `${width}px`
    target.innerHTML = `
      <div class="rotating" >
        <i class="fa-solid fa-spinner"></i>
      </div>
      `
    };
}
