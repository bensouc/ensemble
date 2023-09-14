import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['button', 'domainform', 'beltForm'];
  connect() {
    console.log('add-domain connected');
    document.getElementById("bottom").scrollIntoView({ behavior: "smooth" })
    // window.scrollBy(0, -143);
  }

  // displayForm() {
  //   this.buttonTarget.classList.toggle('d-none');
  //   this.domainformTarget.classList.toggle('d-none');
  //   window.scrollTo(0, document.body.scrollHeight);
  // }


  // TO manage belt selection for special domain cases Géométrie et 'Grandeurs et Mesures' )


}
