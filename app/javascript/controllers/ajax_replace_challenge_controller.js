import {  Controller } from "stimulus";
import swal from 'sweetalert';
import Trix from "trix"
import Rails from "@rails/ujs"
import { type } from "jquery";

export default class extends Controller {
  static targets = ['content', 'challengeDisplay']
  static values = {
    exo: Number
  }


  connect() {
    // this.token = document.querySelector(
    //   'meta[name="csrf-token"]'
    // ).content;
    // console.log(this.token)
    // console.log(this.exoValue)
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

  showCarrousel(event) {
    const challengeId = this.contentTarget.id
    const request = `../challenges/${challengeId}/display_challenges`
    this.fetchContent(request)
  }

  fetchContent(request) {

    fetch(request,
      )
      .then((response) => {
        if (response.status == 200) {
          // hide exo
          // add carrousel
          response.text().then((text) => this.contentTarget.innerHTML = text);
        } else   {
          swal({
            title: "Il n'existe pas d'autre excercice pour cette compétence \n"
                      });
        }
      })
  }
  // data-action="click->ajax-replace-challenge#replaceChallenge"
  replaceChallenge(event) {
    console.log(event.target.parentElement.parentElement.id)
    const newChallengeId = event.target.parentElement.parentElement.id
    const workplanskillId = this.element.id
      // / work_plan_skills /: work_plan_skill_id/change_challenge
    // const request = `../work_plan_skills/${workplanskillId}/change_challenge`
    const request = `../work_plan_skills/${workplanskillId}/change_challenge?${new URLSearchParams({ challenge: newChallengeId  })}`
    this.fetchChallengeContent(request, newChallengeId)
  }

  fetchChallengeContent(request, newChallengeId) {
    fetch(request, {
      method: 'PATCH',
      credentials: "include",
      headers: {
        "X-CSRF-Token": document.querySelector(
          'meta[name="csrf-token"]'
        ).content
      }})
      .then((response) => {
        if (response.status == 200) {
          // hide exo
          // add carrousel
          response.text().then((text) => this.challengeDisplayTarget.innerHTML = text);
        } else {
          console.log("Raté l eval")
        }
      })
  }

}
