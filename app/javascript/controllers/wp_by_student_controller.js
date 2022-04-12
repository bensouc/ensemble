import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['wplist', 'folderopen', 'folderclosed'];
  connect() {
    console.log('wp-by-student');
  }

  displayList() {
    this.folderopenTarget.classList.toggle('d-none');
    this.folderclosedTarget.classList.toggle('d-none');
    this.wplistTarget.classList.toggle('d-none');
  }
}
