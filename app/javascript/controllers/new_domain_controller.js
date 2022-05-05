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


  // TO manage belt selection for special domain cases Géométrie et 'Grandeurs et Mesures' )
  displayBelt(event) {
    // console.log(this);
    const cell = this
    if (event.path[0].value == 'Géométrie' || event.path[0].value == 'Grandeurs et Mesures') {
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
