import { Controller } from "stimulus";
import Sortable from "sortablejs";
import { patch } from "@rails/request.js";
export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    // console.log('add-domain connected');
    this.sortable = Sortable.create(this.element, {
      // handle: ".handle",
      animation: 150,
      delay: 250,
      delayOnTouchOnly: true,
      onEnd: this.end.bind(this)
    })
  }

  end(event) {
    const id = event.item.dataset.id
    const data = new FormData()
    // console.log(id)
    data.append("position", event.newIndex + 1)
    patch(this.urlValue.replace(":id", id),
      {
        body: data
      }
    )
  }
}
