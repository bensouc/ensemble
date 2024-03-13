import { Controller } from "stimulus";
import stripe from '@stripe/stripe-js';
export default class extends Controller {
  connect() {
    console.log('stripe checkout ');
    // initialize();
  }

  async initialize() {
    const response = await fetch("/create-checkout-session", {
      method: "POST",
    });

    const { clientSecret } = await response.json();

    const checkout = await stripe.initEmbeddedCheckout({
      clientSecret,
    });

    // Mount Checkout
    checkout.mount('#checkout');
  }
}
