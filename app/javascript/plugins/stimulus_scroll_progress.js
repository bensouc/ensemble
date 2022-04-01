import { Application } from "@hotwired/stimulus"
import ScrollProgress from "stimulus-scroll-progress"

const application = Application.start()

application.register("scroll-progress", ScrollProgress)
