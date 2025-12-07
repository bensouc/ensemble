// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Auto-load controllers using esbuild-rails
import controllers from './**/*_controller.js'

controllers.forEach((controller) => {
  application.register(controller.name, controller.module.default)
})

export { application }