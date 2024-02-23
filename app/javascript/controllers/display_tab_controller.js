import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['box','tab']

  connect() {
    console.log('display-tab controller Connected')
    console.log(this.boxTargets)
    // this.boxTargets.forEach(target => {
    //   console.log(target)
    // })
  }
  showTab(event) {
    const tabIndex = event.target.dataset.tabId
    console.log(tabIndex)
    this.tabTargets.forEach(tab=>{tab.classList.remove('active')})
    event.target.classList.add('active')
    this.boxTargets.forEach((box, index) => {
      console.log(index)
      box.classList.remove('d-none')
      box.classList.add('d-none')
      console.log(`${index} VS ${tabIndex}`)
      console.log(index === parseInt(tabIndex))
      if (index === parseInt(tabIndex)) {
        console.log("remove d-none")
        box.classList.remove('d-none')
      }
    });
  }
}
