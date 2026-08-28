import { Controller } from "@hotwired/stimulus";

// Soumet le formulaire qui le porte, par Turbo, pour que la réponse remplace la
// frame et rien d'autre.
//
// `submitonchange` ne convient pas ici : il vise en dur le formulaire de filtre
// de l'index (`getElementById('domainForm')`) et appelle `form.submit()`, un
// envoi natif qui contourne Turbo. La page entière se rechargeait — et la modale
// disparaissait avec elle.
//
// `requestSubmit()` déclenche un vrai événement `submit`, que Turbo intercepte :
// le formulaire vivant dans une frame, la réponse ne remplace que celle-ci.
export default class extends Controller {
  submit() {
    this.element.requestSubmit();
  }
}
