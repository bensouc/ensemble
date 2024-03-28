import { Controller } from "stimulus";
export default class extends Controller {
  static targets = ['beltForm', 'box','btn'];
  static values = {
    special: Boolean
  }
  connect() {
    // console.log('add-domain connected');
    console.log(this.btnTargets)
    // this.btnTargets.forEach((btn)=>{
    //   btn.cla
    // })
  }

  displayBelt(event) {
    console.log(this.specialValue)
    // console.log(event.target.value)
    const domain = event.target.nextElementSibling.innerHTML
    if (!this.specialValue) {
      console.log('coucou')
      this.beltFormTarget.classList.remove('d-none');
    } else if ( (domain === 'Géométrie' ||
    domain === 'Grandeurs et Mesures')) {
      this.beltFormTarget.classList.add('d-none');
      // put level 1 checkbox as true
      this.boxTarget.checked = true
      this.boxTarget.value = 1
      this.displayBtn()
    }
    else {
      this.#hideBtn()
      this.beltFormTarget.classList.remove('d-none');
    }

    // document.body.scrollTop = document.body.scrollHeight;
    // document.documentElement.scrollTop = document.documentElement.scrollHeight;
    window.scrollTo(0, document.body.scrollHeight);
  }

  displayBtn(){
    this.btnTargets.forEach((btn) => {
      btn.classList.remove('d-none')
    })
  }
  #hideBtn() {
    this.btnTargets.forEach((btn) => {
      btn.classList.remove('d-none')
      btn.classList.add('d-none')
      console.log("hide btn")
    })
  }
}
