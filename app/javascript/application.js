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
import "@jaames/iro"

// Internal imports
import "./packs/get_anchor"

// Trix editor
import "trix"
import "@rails/actiontext"

// Stimulus controllers
import "./controllers"

// Plugins
import "./plugins/quote"
import "./plugins/trix-editor-overrides"
import "./plugins/stimulus_scroll_progress"

// Rails UJS : gère les liens `method: :delete/:put/:patch` (déconnexion, suppressions…).
// L'app utilise massivement cette syntaxe (data-method) que Turbo seul n'intercepte
// pas (Turbo attend data-turbo-method). Sans ça, ces liens partent en GET → erreur.
Rails.start()

// Initialize on Turbo load
document.addEventListener('turbo:load', () => {
  initFlatpickr();
});