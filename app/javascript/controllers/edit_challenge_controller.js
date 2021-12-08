import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['infos', 'form', 'preview', 'button'];

  displayForm() {
    this.infosTarget.classList.add('d-none');
    console.log(this.formTarget)
    this.formTarget.classList.remove('d-none');
  }

  preview(event) {
    const selectTag = event.target
    const options = selectTag.options
    const selectedOption = options[options.selectedIndex]
    const content = `${selectedOption.dataset.content}`

    this.infosTarget.classList.add('d-none');
    this.previewTarget.innerHTML = JSON.parse(content)
    this.previewTarget.classList.remove('d-none');
  }
}
