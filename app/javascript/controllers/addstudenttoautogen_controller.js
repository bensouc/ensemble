import { Controller } from "stimulus";


export default class extends Controller {
  static targets = ['form','text']


  connect() {
    // console.log('addstudenttoautogen connected');
  }

  addStudentId(event) {
    const studentId = event.target.parentElement.dataset.studentId;
    const studentName = event.target.parentElement.dataset.studentName;
    const boxes = this.formTarget.querySelectorAll('input[type="checkbox"]')
    this.formTarget.action = `/students/${studentId}`;
    this.textTarget.innerText = `Déselectionner les domaines non souhaités ${studentName}`;
    boxes.forEach((box) => {
      box.checked = true;
    })
  }

}
