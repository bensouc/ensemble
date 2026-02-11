import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['lastEval']
  connect() {
    // console.log('ajax-work-plan');
  }

  toggle(event) {
    event.preventDefault()
    event.stopImmediatePropagation()

    const href = event.target.parentElement?.href || event.target.closest('a')?.href
    // Validate URL before making request
    if (!href || href.includes('undefined') || href.includes('null')) {
      console.error('Invalid URL detected:', href)
      return
    }

    this.request = new Request(href, {
      method: 'PATCH',
      credentials: "include",
      headers: {
        "X-CSRF-Token": document.querySelector(
          'meta[name="csrf-token"]'
        ).content
      }});
    this.fetchContent(this.request);
  }

  fetchContent(request) {
    fetch(request)
      .then((response) => {
        if (response.status == 200) {
          response.text().then((text) => this.lastEvalTarget.innerHTML = text);
        } else {
          console.log("Raté l eval")
        }
      })
  }
}
