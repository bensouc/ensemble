import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['wpsBox'];

  connect() {
    // console.log('add wps controlelr connected');
  }

    validateWps(event) {
      console.log(event.target.href);
      event.preventDefault()
      this.request = new Request(event.target.href);
      this.fetchContent(this.request);
      // change domain name

  }

  fetchContent(request) {
    fetch(request)
      .then((response) => {
        if (response.status == 200) {
          response.text().then((text) => this.wpsBoxTarget.innerHTML = text);
        } else {
         console.log('Raté');
        }
      })
  }
}
