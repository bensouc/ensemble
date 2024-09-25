import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['conversation'];

  connect() {

  }
  addActive(event) {
    this.conversationTargets.forEach((conversation) => {
      conversation.classList.remove("active")
      if (conversation.contains(event.target)) {
        conversation.classList.add("active")
      }
    });
  }
}
