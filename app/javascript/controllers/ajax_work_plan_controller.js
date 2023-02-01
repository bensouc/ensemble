import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['lastEval']
  connect() {
    // console.log('ajax-work-plan');
  }

  toggle(event) {
    this.request = new Request(event.target.parentElement.href);
    console.log(this.request)
    event.preventDefault()
    event.stopImmediatePropagation()
    this.fetchContent(this.request);
    // change domain name
    // this.lastEvalTarget.innerHTML = event.target.innerHTML
  }

  fetchContent(request) {
    fetch(request,)
      .then((response) => {
        if (response.status == 200) {
          response.text().then((text) => this.lastEvalTarget.innerHTML = text);
        } else {
          console.log("Raté l eval")
        }
      })
  }
}
