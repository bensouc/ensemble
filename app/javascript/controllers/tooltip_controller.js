import { Controller } from "@hotwired/stimulus";
import { Tooltip } from "bootstrap";

export default class extends Controller {
  connect() {
    // console.log('connected')
    new Tooltip(this.element)
  }
}
