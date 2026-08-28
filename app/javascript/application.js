// Entry point for the build script in your package.json

// Rails imports
import Rails from "@rails/ujs"
import "@rails/activestorage"
import "./channels"

// External imports
import "bootstrap"
import "@hotwired/turbo-rails"
import { initFlatpickr } from "./plugins/flatpickr"
import "@rails/request.js"
import "@stripe/stripe-js"

// Internal imports
import "./packs/get_anchor"

// Trix editor — la config doit être importée juste apres `trix` et avant
// les controllers, pour etre en place avant l'init du premier editeur.
import "trix"
import "./plugins/trix-config"
import "@rails/actiontext"

// Stimulus controllers
import "./stream_actions"
import "./controllers"

// Plugins
import "./plugins/confirm_dialog"
import "./plugins/quote"
import "./plugins/trix-editor-overrides"
import "./plugins/stimulus_scroll_progress"

// Rails UJS : gère les liens `method: :delete/:put/:patch` (déconnexion, suppressions…).
// L'app utilise massivement cette syntaxe (data-method) que Turbo seul n'intercepte
// pas (Turbo attend data-turbo-method). Sans ça, ces liens partent en GET → erreur.
Rails.start()

// Service worker : lecture hors ligne du front mobile. Enregistré seulement sur
// un contexte sécurisé — https en production, localhost en développement — car
// un service worker y est refusé partout ailleurs. Son échec ne doit rien
// casser : sans lui on perd la consultation hors réseau, pas l'application.
if ("serviceWorker" in navigator && window.isSecureContext) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker.js").catch(() => {});
  });
}

// Initialize on Turbo load
document.addEventListener('turbo:load', () => {
  initFlatpickr();
});

// Les modales et formulaires chargés dans une frame Turbo ne déclenchent pas
// `turbo:load` : sans ça, un champ date arrivé par frame reste un champ texte.
document.addEventListener('turbo:frame-load', () => {
  initFlatpickr();
});