import { Controller } from "@hotwired/stimulus";

// « Vous consultez des données du … » — quand la page vient du cache.
//
// Le service worker estampille les pages qu'il sert hors réseau. Sans ce
// bandeau, un enseignant évaluerait sur une classe périmée sans le savoir :
// c'est exactement la situation où l'on prend une mauvaise décision en croyant
// être informé.
export default class extends Controller {
  static targets = ["message"];

  connect() {
    const horodatage = document.querySelector('meta[name="servi-depuis-cache"]')?.content;
    if (!horodatage) return;

    const date = new Date(horodatage);
    if (Number.isNaN(date.valueOf())) return;

    this.messageTarget.textContent = `Hors réseau — vous consultez les données du ${this.formater(date)}.`;
    this.element.hidden = false;
  }

  formater(date) {
    return new Intl.DateTimeFormat("fr-FR", {
      day: "numeric",
      month: "long",
      hour: "2-digit",
      minute: "2-digit",
    }).format(date);
  }
}
