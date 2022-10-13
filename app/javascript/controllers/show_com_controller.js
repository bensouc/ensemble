import { Controller } from "stimulus";
import swal from 'sweetalert';


export default class extends Controller {



  displayCom() {
    swal({
      title: "Ensemble change d'adresse !! \n www.app-ensemble.fr",
      text: "\n Depuis hier, l'application est disponible à cette nouvelle adresse \n Penser à mettre à jour vos liens, et notamment sur le mobile. \n \n L'ancienne adresse ne sera plus disponible à partir du 28 novembre",
      icon: "info"
    });
  }
}
