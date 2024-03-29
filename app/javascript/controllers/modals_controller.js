//open_modal_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    // console.log('modal open connetec')
  }
  emptyModal(){
    const modal = document.querySelector('.modal-ensemble')
    modal.classList.add('d-none')
  }
}
