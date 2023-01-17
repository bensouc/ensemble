import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["tab", 'results', 'domainnamedisplay', "domainName"]
  connect() {
    // console.log('test dds connected');
  }
  toggle(event) {
    // console.log(event.target.href)
    event.preventDefault()
    this.request = new Request(event.target.href);
    this.fetchContent(this.request);
    // change domain name
    this.domainnamedisplayTarget.innerHTML = event.target.innerHTML
  }

  fetchContent(request) {
    fetch(request)
      .then((response) => {
        if (response.status == 200) {
          response.text().then((text) => this.resultsTarget.innerHTML = text);
        } else {
          console.log("Couldn't load data");
        }
      })
  }


}
