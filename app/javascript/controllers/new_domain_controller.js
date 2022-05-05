import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['button', 'domainform', 'beltForm', 'box'];
  connect() {
    // console.log('add-domain connected');
  }

  displayForm() {
    this.buttonTarget.classList.toggle('d-none');
    this.domainformTarget.classList.toggle('d-none');
    window.scrollTo(0, document.body.scrollHeight);
  }

  displayBelt(event) {
    // console.log(this);
    const cell = this
    if (event.path[0].value == 'Géométrie' || event.path[0].value =='Grandeurs et Mesures') {
      // console.log(cell);
      // console.log(this);
      // console.log(cell.boxTarget.checked);
      cell.beltFormTarget.classList.add('d-none');
      cell.boxTarget.checked = true
      // console.log(cell.boxTarget.checked);
    } else {
      this.beltFormTarget.classList.remove('d-none');
    }

  }

}
