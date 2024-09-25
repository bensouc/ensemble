import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['messages', 'avatar'];
  static values = {
    userId: Number
  }

  connect() {
    // console.log(this.element);
    // triggered when a new message is added to the page
    const currentUserId = parseInt(document.body.dataset.currentUserId, 10);
    if (this.userIdValue === currentUserId) {
      this.element.classList.add('writer');
      this.avatarTarget.classList.add("d-none")
    } else {
      this.avatarTarget.classList.remove("d-none")
      this.element.classList.remove('writer');
    }
    // this.element.scrollIntoView({ behavior: 'smooth' }); // scroll to the bottom of the page
    this.scrollToBottom();
  }
  // initialize() {
  //   this.element.addEventListener("turbo:before-stream-render", this.#scrollToBottom.bind(this));
  // }

  scrollToBottom() {
    const messages = document.getElementById("messages");
    messages.scrollTop = messages.scrollHeight;
  }
  // Ajoutez cette méthode pour écouter les événements Turbo Streams
}
