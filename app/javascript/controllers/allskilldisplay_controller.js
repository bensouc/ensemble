import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['levelSkillCard', 'leveltBtn', 'domainBtn', 'skillCard', 'domainCard']
  connect() {
    // this.setUpSkillsDisplay()
    // console.log(this.domainBtnTargets);
  }

  displaySkills(event) {
    // console.log(event.currentTarget.dataset.level);
    this.removeLevelBtnActive()
    event.currentTarget.classList.add('active');
    this.levelSkillCardTargets.forEach(element => {
      if (element.dataset.level == event.currentTarget.dataset.level) {
        element.classList.remove('d-none')
      } else {
        element.classList.add('d-none')
      };
    });
  }

  // event.currentTarget.classList.toggle('active')
  // displayDomain(event) {
  //   // console.log('event');
  //   this.removeDomainBtnActive()
  //   this.removeLevelBtnActive()
  //   this.setDomainActive(event)
  //   // add active Class to first level Btn
  //   this.leveltBtnTargets[0].classList.add('active')
  //   this.displaySkillsByDomain(event)

  // }

  // FACTORISATION

  // setUpSkillsDisplay() {
  //   this.leveltBtnTargets[0].classList.add('active')
  //   // this.domainBtnTargets[0].classList.add('active')
  //   // remove d-none on all first level
  //   this.displayLevel1()
  // }
  removeLevelBtnActive() {
    // this.levelSkillCardTargets.forEach(element => {
    this.leveltBtnTargets.forEach(btn => {
      btn.classList.remove('active');
    })
  }
  // removeDomainBtnActive() {
  //   this.domainBtnTargets.forEach(btn => {
  //     btn.classList.remove('active');
  //   })
  // }
  // displayLevel1() {
  //   this.levelSkillCardTargets.forEach(element => {
  //     if (element.dataset.level == 1) {
  //       element.classList.remove('d-none')
  //     } else {
  //       element.classList.add('d-none')
  //     };
  //   });
  // }

  // displaySkillsByDomain(event) {
  //   this.domainCardTargets.forEach(element => {
  //     if (element.dataset.domain.trim() === event.currentTarget.dataset.domain.trim()) {
  //       element.classList.remove('d-none')
  //       // display first level of domain
  //     } else {
  //       element.classList.add('d-none')
  //     };
  //   })
  // }
  // setDomainActive(event) {
  //   this.domainBtnTargets.forEach(btn => {
  //     if (btn.dataset.domain.trim() === event.currentTarget.dataset.domain.trim()) {
  //       btn.classList.add('active')
  //       // display first level of domain
  //     } else {
  //       btn.classList.remove('active')
  //     };
  //   })
  // }


}
