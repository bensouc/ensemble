import { Controller } from "@hotwired/stimulus"
import Trix from "trix"
import Rails from "@rails/ujs"

// Ajoute le bouton « Tableau » au groupe file-tools de la toolbar Trix.
export default class extends Controller {
  connect() {
    // Trix 2 définit ses custom elements dans un `setTimeout(start, 0)`, donc
    // APRÈS que Stimulus a connecté ce contrôleur (Stimulus démarre sur une
    // microtâche après DOMContentLoaded, avant la macrotâche du timer). Au
    // moment du connect, <trix-editor> n'est donc pas encore initialisé et sa
    // toolbar n'existe pas : chercher le groupe file-tools renvoyait null.
    //
    // On attend `trix-initialize` (qui remonte jusqu'ici), avec un essai
    // immédiat pour le cas où l'éditeur serait déjà prêt — reconnexion du
    // contrôleur, navigation Turbo, morphing.
    this.addTableButton = this.addTableButton.bind(this)
    this.element.addEventListener("trix-initialize", this.addTableButton)
    this.addTableButton()
  }

  disconnect() {
    this.element.removeEventListener("trix-initialize", this.addTableButton)
  }

  addTableButton() {
    const fileTools = this.element.querySelector("[data-trix-button-group=file-tools]")
    if (!fileTools) return
    // L'essai immédiat et l'événement peuvent tous deux aboutir.
    if (fileTools.querySelector(".trix-button--icon-table")) return

    const label = Trix.config.lang.table
    fileTools.insertAdjacentHTML("beforeend", `
      <button type="button" class="trix-button trix-button--icon trix-button--icon-table"
              data-action="rich-text-table#attachTable"
              title="${label}" aria-label="${label}" tabindex="-1">${label}</button>
    `)
  }

  attachTable() {
    Rails.ajax({
      url: "/tables",
      type: "post",
      success: this.insertTable.bind(this)
    })
  }

  insertTable(tableAttachment) {
    const editor = this.element.querySelector("trix-editor")
    if (!editor?.editor) return

    editor.editor.insertAttachment(new Trix.Attachment(tableAttachment))
    editor.focus()
  }
}
