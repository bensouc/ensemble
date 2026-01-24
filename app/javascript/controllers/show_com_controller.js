import { Controller } from "@hotwired/stimulus";
import swal from 'sweetalert';


export default class extends Controller {



  displayCom() {
    swal({
      title: "Ensemble Vous souhaite de belles vacances !! \n",
      text:
        "Nous restons ouverts pendant les fêtes, n'hesitez pas, " +
        'contact@vroadstudio.fr'
    });
  }
}
