import flatpickr from "flatpickr";
import { French } from "flatpickr/dist/l10n/fr.js"


const initFlatpickr = () => {
  flatpickr(".datepicker", { dateFormat: 'd/m/Y', locale: French, allowInput: true });
  // flatpickr(".datepicker",{dateFormat: 'd/m/Y'})
}

export { initFlatpickr };
