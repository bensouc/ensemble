import { Controller } from "stimulus";
export default class extends Controller {
  static targets = ['beltForm', 'box'];
  static values = {
    grade: String

  }
  connect() {
    // console.log('add-domain connected');
  }

  displayBelt(event) {

    if (this.element.id === 'CM2') {
      this.beltFormTarget.classList.remove('d-none');
    } else if ((this.gradeValue != "CM2") &&
      (event.target.value === 'Géométrie' ||
        event.target.value === 'Grandeurs et Mesures' ||
        event.target.value === 'Poésie')) {
      this.beltFormTarget.classList.add('d-none');
      // put level 1 checkbox as true
      this.boxTarget.checked = true
    }
    else {
      this.beltFormTarget.classList.remove('d-none');
    }

    // document.body.scrollTop = document.body.scrollHeight;
    // document.documentElement.scrollTop = document.documentElement.scrollHeight;
    window.scrollTo(0, document.body.scrollHeight);
  }
}
