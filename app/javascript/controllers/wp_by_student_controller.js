import { Controller } from "stimulus";
import Swal from 'sweetalert2'
export default class extends Controller {
  static targets = ['count', 'wplist', 'folderopen', 'folderclosed', 'wpLine'];
  connect() {
    // console.log('wp-by-student');
  }

  displayList() {
    this.folderopenTarget.classList.toggle('d-none');
    this.folderclosedTarget.classList.toggle('d-none');
    this.wplistTarget.classList.toggle('d-none');

  }

  deleteWorkPlan(event) {

    event.preventDefault()
    event.stopImmediatePropagation()
    Swal.fire({
      title: 'Voulez vous Supprimer Ce Plan de Travail?',
      showDenyButton: true,
      // showCancelButton: true,
      confirmButtonText: 'Oui',
      denyButtonText: `Non`,
    }).then((result) => {
      /* Read more about isConfirmed, isDenied below */
      if (result.isConfirmed) {
        // console.log(event.target.parentElement.parentElement.parentElement.action)
        this.request = new Request(event.target.parentElement.parentElement.parentElement.action, {
          method: 'DELETE',
          credentials: "include",
          headers: {
            "X-CSRF-Token": document.querySelector(
              'meta[name="csrf-token"]'
            ).content
          }
        });
        // console.log(this.request)
        this.removeWorkPlanContent(this.request)
        this.updateNbWp()
      } else if (result.isDenied) {
        // Swal.fire('Changes are not saved', '', 'info')
      }
    })


  }

  removeWorkPlanContent(request) {
    console.log(request)
    fetch(request)
      .then((response) => {
        if (response.status == 200) {
          this.wpLineTarget.remove();
        } else {
          console.log("Raté le delete")
        }
      })
  }

  updateNbWp() {
    const count = this.wpLineTargets.length
    // console.log(this.countTarget.innerHTML)
    if (count > 2) {
      // console.log(this.countTarget.innerHTML)
      this.countTarget.innerHTML = `( ${count - 1} Plans de travail )`
      // index - wp - count
    } else {
      this.countTarget.innerHTML = `( ${count - 1} Plan de travail )`
    }
  }

}
