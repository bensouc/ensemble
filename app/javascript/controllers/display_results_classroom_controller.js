import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["tab", 'results', 'domainnamedisplay', "domainName"]
  connect() {
    this.tabTargets[0].classList.add('active')
  }

  getActiveTab(event) {
    this.tabTargets.forEach(element => {
      element.classList.remove('active')
      event.target.classList.add('active')
    });
  }
  toggle(event) {
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
          this.resultsTarget.innerHTML = "Ce domaine ne dispose pas compétence";
        }
      })
  }
}
