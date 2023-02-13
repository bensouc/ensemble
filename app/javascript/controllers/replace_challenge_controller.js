import { Controller } from "stimulus";
import Trix from "trix"
import Rails from "@rails/ujs"
import { type } from "jquery";

export default class extends Controller {
  static targets = ['content'];


  connect() {
    // console.log('Coucouscous')
    // this.infosTarget.classList.add('d-none');
    // this.formTarget.classList.remove('d-none');
  }

  cloneChallenge(event) {
    event.preventDefault()
    event.stopImmediatePropagation()
    // console.log('challenge clonig start')
    const challengeId = this.contentTarget.id

    if (this.contentTarget.getElementsByTagName("action-text-attachment")[0].attributes[1].value == "application/octet-stream") {

      const originalSgid = this.contentTarget.getElementsByTagName("action-text-attachment")[0].attributes.sgid.value
      this.cloneChallengeWithTable(originalSgid, challengeId)
    }

  }


  cloneChallengeWithTable(sgid, challengeId) {
    // console.log(sgid)
    const request = `/tables/${sgid}/clone?challenge_id=${challengeId}`
    fetch(request, {
      headers: {
        'Accept': 'application/json',
      }
    })
      .then((response) => response.json())
      // .then(text => console.log(text))
      .then(json => {
        // console.log(json)
        return json
      })
   }
}
