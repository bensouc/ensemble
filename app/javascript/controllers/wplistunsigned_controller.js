import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['wplistus', 'folderopen', 'folderclosed'];
  connect() {
    console.log('wplistus');
  }

  displayList() {
    this.folderopenTarget.classList.toggle('d-none');
    this.folderclosedTarget.classList.toggle('d-none');
    this.wplistusTarget.classList.toggle('d-none');
  }
}
