// app/javascript/controllers/lazy_load_controller.js
import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["frame"]

  connect() {
    this.loadFrames()
    console.log(this.frameTargets)
  }

  loadFrames() {
    const totalFrames = this.frameTargets.length
    let delayPerFrame = 0

    if (totalFrames >= 40) {
      delayPerFrame = 1000 / totalFrames // 2 seconds divided by the number of frames
    }

    this.frameTargets.forEach((frame, index) => {
      const delay = index * delayPerFrame
      setTimeout(() => {
        frame.src = frame.dataset.src;
        console.log("Frame loaded")
      }, delay)
    })
  }
}
