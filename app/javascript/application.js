// Entry point for the build script in your package.json

// Rails imports
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

// Initialize on Turbo load
document.addEventListener('turbo:load', () => {
  initFlatpickr();
});