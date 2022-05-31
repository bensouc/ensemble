import { Controller } from "stimulus";
export default class extends Controller {
  static targets = ['beltForm'];
  connect() {
    // console.log('add-domain connected');
  }

  displayBelt(event) {
    // console.log(this.element);
    console.log(event.target.value);
    const cell = this
    // if (event.path[0].value == 'Géométrie' || event.path[0].value == 'Grandeurs et Mesures') {
      if (event.target.value == 'Géométrie' || event.target.value == 'Grandeurs et Mesures') {
      this.beltFormTarget.classList.add('d-none');
      // put level 1 checkbox as true
      this.boxTarget.checked = true
    } else {
      this.beltFormTarget.classList.remove('d-none');
    }
    // document.body.scrollTop = document.body.scrollHeight;
    // document.documentElement.scrollTop = document.documentElement.scrollHeight;
    window.scrollTo(0, document.body.scrollHeight);
  }
}
