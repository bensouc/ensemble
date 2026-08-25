import { Controller, fetch } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['form', 'rythm', 'quantity', 'renewDate', 'totalCost', 'monthlyCost']
  static values = { tarifs: Object };
  connect() {
    console.log("calculate sub connected");
    // console.log(this.formTarget);
    // console.log(this.renewDateTarget.value);
    // console.log(this.totalCostTarget.value);
    // console.log(this.monthlyCostTarget.value);

  }
  calculate() {
    // console.log('calculate');
    // console.log(this.tarifsValue)
    // const url = '../subscriptions/on_boarding';
    const tarifs = this.tarifsValue
    const rythm = this.rythmTarget.value
    const quantity = Number(this.quantityTarget.value) || 0
    // Seul l'INDICE du barème se plafonne : `TARIFS[:annualy]` s'arrête à 9, et
    // au-delà le tarif unitaire ne bouge plus (46 €). La quantité réelle reste
    // le multiplicateur — la branche mensuelle utilisait l'indice plafonné, et
    // annonçait 45 € pour 12 classes là où Stripe en facture 60.
    const palier = Math.min(quantity, tarifs.annualy.length - 1)

    if (rythm === 'Mensuel') {
      const cout = tarifs.monthly * quantity
      this.totalCostTarget.value = `${cout} €`
      this.monthlyCostTarget.value = `${cout} €`
      this.renewDateTarget.value = this.#define_renew_date('Mensuel')
    }
    else
    {
      const annual_cost = tarifs.annualy[palier] * quantity
      this.totalCostTarget.value = `${annual_cost} €`
      this.monthlyCostTarget.value = `${(annual_cost / 12).toFixed(2)} €`
      this.renewDateTarget.value = this.#define_renew_date()
    }
}

#define_renew_date(rythm){
  let date = new Date();
  // Si le rythme est mensuel, ajouter un mois
  if (rythm === "Mensuel") {
    date.setMonth(date.getMonth() + 1);
  }
  // Si le rythme est annuel, ajouter un an
  else {
    date.setFullYear(date.getFullYear() + 1);
  }

  // Ajouter 25 jours
  date.setDate(date.getDate() + 25);

  // Ajouter 1 mois
  date.setMonth(date.getMonth() + 1);

  // Récupérer le jour, le mois et l'année
  let jour = String(date.getDate()).padStart(2, '0');
  let mois = String(date.getMonth() + 1).padStart(2, '0'); // Ajout de 1 car les mois commencent à 0
  let annee = date.getFullYear();

  // Formater la date au format "jour/mois/année"
  return `${annee}-${mois}-${jour}`;
}
}
