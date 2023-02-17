import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['infos', 'form', 'preview', 'button',"pencil"];

  connect(){
    // console.log('pencil connectéééé')
  }

  displayForm() {
    console.log(this.targets)
    this.infosTarget.classList.add('d-none');
    this.formTarget.classList.remove('d-none');
    this.pencilTarget.classList.add('d-none')
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
