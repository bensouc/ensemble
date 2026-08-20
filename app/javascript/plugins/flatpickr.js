import flatpickr from "flatpickr";
import { French } from "flatpickr/dist/l10n/fr.js"


const initFlatpickr = () => {
  // Un champ déjà équipé porte `_flatpickr` : sans ce garde, chaque appel créerait
  // un second calendrier sur le même champ.
  document.querySelectorAll(".datepicker").forEach((input) => {
    if (input._flatpickr) return;

    flatpickr(input, { dateFormat: 'd/m/Y', locale: French, allowInput: true });
  });
}

export { initFlatpickr };
