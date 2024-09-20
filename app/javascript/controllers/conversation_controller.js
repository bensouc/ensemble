import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['messages'];

  connect() {
    console.log('controller conversation is connected');
    this.scrollToBottom();
  }
  // initialize() {
  //   this.element.addEventListener("turbo:before-stream-render", this.#scrollToBottom.bind(this));
  // }

  scrollToBottom() {
    // const messages = this.messagesTarget;
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
  }
  // Ajoutez cette méthode pour écouter les événements Turbo Streams
}
