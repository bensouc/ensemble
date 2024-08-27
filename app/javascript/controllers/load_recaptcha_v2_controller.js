import { Controller } from "stimulus"

export default class extends Controller {
  static values = { siteKey: String }

  initialize() {
    console.log("coucou")
    this.loadRecaptcha()
  }

  loadRecaptcha() {
    if (typeof grecaptcha !== "undefined") {
      grecaptcha.ready(() => {
        grecaptcha.render("recaptchaV2", { sitekey: this.siteKeyValue })
      })
    } else {
      console.error("reCAPTCHA n'est pas chargé")
    }
  }
}
