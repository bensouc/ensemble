import { Controller } from "@hotwired/stimulus"
import iro from '@jaames/iro';


export default class extends Controller {
  static targets = ["picker"]

  connect() {
    this.colorPicker = new iro.ColorPicker(this.pickerTarget, {
      width: 280,
      color: this.defaultValue,
      layout: [
        {
          component: iro.ui.Box,
          options: {
            boxHeight: 160
          }
        },
        {
          component: iro.ui.Slider,
          options: {
            sliderType: "hue",
          }
        },
      ]
    })


    this.colorPicker.on("input:change", (color) => {
      this.dispatch("change", {
        detail: color.hexString
      })
    })

    this.colorPicker.on("color:change", (color) => {
      this.dispatch("change", {
        detail: color.hexString
      })
    })
  }
}
