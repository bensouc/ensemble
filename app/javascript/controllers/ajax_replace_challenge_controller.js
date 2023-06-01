import { Controller } from "stimulus";
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
    // const workplanskillId =this.con
    console.log(event.target.parentElement.parentElement.action)
    this.request = new Request(event.target.parentElement.parentElement.action, {
      method: 'POST',
      credentials: "include",
      headers: {
        "X-CSRF-Token": document.querySelector(
          'meta[name="csrf-token"]'
        ).content
      }
    })
    // show temp
    this.contentTarget.innerHTML = '<div class="spinner-border --rose " role="status"></div >'
    this.fetchFullChallenge(this.request)
  }


  fetchFullChallenge(request) {
    // console.log(sgid)

    fetch(request)
      .then((response) => {
        if (response.status == 200) {
          response.text().then((text) => this.challengeDisplayTarget.innerHTML = text);
        } else {
          console.log("Raté l eval")
        }
      })
  }

  showCarrousel(event) {
    const challengeId = this.contentTarget.id
    const request = `../challenges/${challengeId}/display_challenges`
    this.fetchCarrouselContent(request)
  }

  fetchCarrouselContent(request) {

    fetch(request,
    )
      .then((response) => {
        if (response.status == 200) {
          // hide exo
          // add carrousel
          response.text().then((text) => this.contentTarget.innerHTML = text);
        } else {
          swal({
            title: "Il n'existe pas d'autre exercice pour cette compétence \n"
          });
        }
      })
  }
  // data-action="click->ajax-replace-challenge#replaceChallenge"
  replaceChallenge(event) {
    // console.log(event.target.parentElement.parentElement.id)
    const newChallengeId = event.target.parentElement.parentElement.id
    const workplanskillId = this.element.id
    // / work_plan_skills /: work_plan_skill_id/change_challenge
    // const request = `../work_plan_skills/${workplanskillId}/change_challenge`
    const url = `../work_plan_skills/${workplanskillId}/change_challenge?${new URLSearchParams({ challenge: newChallengeId })}`
    this.request = new Request(url, {
      method: 'PATCH',
      credentials: "include",
      headers: {
        "X-CSRF-Token": document.querySelector(
          'meta[name="csrf-token"]'
        ).content
      }
    })
    this.fetchFullChallenge(this.request)
  }

  closeCarrousel(event){
    const workplanskillId = this.element.id
    const challengeId = this.contentTarget.id
    console.log(challengeId)
    this.request = new Request(`../challenges/${challengeId}?work_plan_skill_id=${workplanskillId}`)


    this.fetchFullChallenge(this.request)

  }
}
