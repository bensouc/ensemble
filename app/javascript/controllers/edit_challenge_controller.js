import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['infos', 'form', 'preview',"pencil"];

  connect(){
    // console.log('pencil connectéééé')
  }

  displayForm() {
    // console.log(this.targets)
    // In order resolve bad URL
    this.formTarget.innerHTML = this.formTarget.innerHTML.replace('www.ensemble.lt', 'www.app-ensemble.fr')
    this.infosTarget.classList.add('d-none');
    this.formTarget.classList.remove('d-none');
    // this.pencilTarget.classList.add('d-none')
  }

  hideForm(){
    // console.log('prout')
    this.infosTarget.classList.remove('d-none');
    // this.pencilTarget.classList.remove('d-none')
    this.formTarget.classList.add('d-none');
  }
}
