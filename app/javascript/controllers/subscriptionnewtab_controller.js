import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['tab1', 'tab2', 'separator', 'monthlysub', 'annualysub'] // connect(){
  connect() {
    console.log('sibcription new connected');
  }

  displayAnnual(event) {
    this.tab1Target.classList.remove('active');
    this.tab1Target.classList.add('active');
    this.separatorTarget.classList.remove('active');
    this.separatorTarget.classList.add('active');
    this.tab2Target.classList.remove('active');
    this.showThisTab(this.annualysubTarget)
    this.hideThisTab(this.monthlysubTarget)

  }
  displayMontlhy(event) {
    this.tab2Target.classList.remove('active');
    this.tab2Target.classList.add('active');
    this.separatorTarget.classList.remove('active');
    this.tab1Target.classList.remove('active');
    this.showThisTab(this.monthlysubTarget)
    this.hideThisTab(this.annualysubTarget)
  }

  showThisTab(tab) {
    tab.classList.remove('d-none');
  }
  hideThisTab(tab) {
    console.log(tab);
    tab.classList.remove('d-none');
    tab.classList.add('d-none');
  }
}
