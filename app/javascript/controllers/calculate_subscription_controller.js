import { Controller, fetch } from "stimulus";

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
    console.log('calculate');
    console.log(this.tarifsValue)
    // const url = '../subscriptions/on_boarding';
    const tarifs = this.tarifsValue
    const rythm = this.rythmTarget.value;
    let quantity = this.quantityTarget.value || 0;
    if (quantity >= 9) { quantity = 9 }
    if (rythm === 'Mensuel'){
      this.totalCostTarget.value = `${tarifs.monthly * quantity} €`
      this.monthlyCostTarget.value = `${tarifs.monthly * quantity} €`
      this.renewDateTarget.value = this.#define_renew_date('Mensuel')
    }
    else
    {
      const annual_cost = tarifs.annualy[quantity] * this.quantityTarget.value
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
  return `${jour}/${mois}/${annee}`;
}
}
