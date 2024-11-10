import { Controller } from "@hotwired/stimulus";
import { Tooltip } from "bootstrap";

export default class extends Controller {
  connect() {
    // console.log('connected')
    this.tooltip = new Tooltip(this.element)
  }
  disconnect() {
    // console.log('disconnected')
    if (this.tooltip) {
      this.tooltip.dispose();
    }
  }
}
