import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values =
  {
    anchor: String
  };

  connect() {
    console.log('go to ANchor connected');
  }

  getDown() {

  window.scrollTo({
    top: window.innerHeight, // Hauteur de la fenêtre du navigateur (viewport)
    behavior: 'smooth' // Pour une transition fluide
  });
  }
}
