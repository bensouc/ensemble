import { Controller } from "stimulus"

// data-controller="loading-spinner2"
export default class extends Controller {
  static targets = ["content"]

  connect() {
    console.log('spinner 2  controller connected');
  }
  displayLoadingSpinner() {
    this.contentTargets.forEach(element => {
      element.innerHTML = '<div class="w-100"><div class="spinner-border --rose" role="status"></div ></div >'
    });
  }
}
