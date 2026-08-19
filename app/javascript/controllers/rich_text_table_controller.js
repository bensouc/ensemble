import { Controller } from "@hotwired/stimulus"
import Trix from "trix"
import Rails from "@rails/ujs"

let lang = Trix.config.lang;

export default class extends Controller {

  connect() {
    // console.log("connexion")
    // `lang.table` est défini dans plugins/trix-config.js avec les autres libellés.
    var tableButtonHTML = `<button type="button" class="trix-button trix-button--icon trix-button--icon-table" data-action="rich-text-table#attachTable" title="${lang.table}" aria-label="${lang.table}" tabindex="-1">${lang.table}</button>`
    var fileToolsElement = this.element.querySelector('[data-trix-button-group=file-tools]')
    fileToolsElement.insertAdjacentHTML("beforeend", tableButtonHTML)
  }

  attachTable(event) {
    Rails.ajax({
      url: `/tables`,
      type: 'post',
      success: this.insertTable.bind(this)
    })
  }

  insertTable(tableAttachment) {
    this.attachment = new Trix.Attachment(tableAttachment)
    this.element.querySelector('trix-editor').editor.insertAttachment(this.attachment)
    this.element.focus()
  }
}
