import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['levelSkillCard', 'leveltBtn', 'domainBtn', 'skillCard', 'domainCard']
  connect() {
    this.setUpSkillsDisplay()
  }

  displaySkills(event) {
    // console.log(event.currentTarget.dataset.level);
    this.removeSkillsBtnActive()
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
  displayDomain(event) {
    // console.log('remove active on domain btn');
    this.removeDomainBtnActive()
    event.currentTarget.classList.add('active');
    // reset level btns
    this.removeSkillsBtnActive()
    // add active Class to first level Btn
    this.leveltBtnTargets[0].classList.add('active')
    this.displayDomain(event)

  }

  // FACTORISATION

  setUpSkillsDisplay() {
    this.leveltBtnTargets[0].classList.add('active')
    this.domainBtnTargets[0].classList.add('active')
    // remove d-none on all first level
    this.displayLevel1()
  }
  removeSkillsBtnActive() {
    // this.levelSkillCardTargets.forEach(element => {
    this.leveltBtnTargets.forEach(btn => {
      btn.classList.remove('active');
    })
  }
  removeDomainBtnActive() {
    this.domainBtnTargets.forEach(btn => {
      btn.classList.remove('active');
    })
  }
  displayLevel1() {
    this.levelSkillCardTargets.forEach(element => {
      if (element.dataset.level == 1) {
        element.classList.remove('d-none')
      } else {
        element.classList.add('d-none')
      };
    });
  }

  displayDomain(event) {
    this.domainCardTargets.forEach(element => {
      if (element.dataset.domain.trim() === event.currentTarget.dataset.domain.trim()) {
        element.classList.remove('d-none')
        // display first level of domain
      } else {
        element.classList.add('d-none')
      };
    })
  }
}
