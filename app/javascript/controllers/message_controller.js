import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['messages'];

  connect() {
    console.log('controller message is connected');
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
