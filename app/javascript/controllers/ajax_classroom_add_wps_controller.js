import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['wpsBox'];

  connect() {
    // console.log('add wps controlelr connected');
  }

    validateWps(event) {
      event.preventDefault()
      event.stopImmediatePropagation()
      console.log(event.target.href);
      // let method = 'POST'
      // if (event.target.href.includes('remove'))
      // {method = 'DELETE' }
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
