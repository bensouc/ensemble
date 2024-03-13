# rubocop:disable all

class Stripe::StripeWebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  # skip_before_action :verify_authenticity_token

  def create
    skip_authorization
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET_KEY"]
      )
    rescue JSON::ParserError => e
      status 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      puts "Signature error"
      p e
      return
    end

    # Handle the event

    case event.type
    when "checkout.session.completed"
      session = event.data.object
      session_with_expand = Stripe::Checkout::Session.retrieve({ id: session.id, expand: ["line_items"] })
      session_with_expand.line_items.data.each do |line_item|
        product = Product.find_by(stripe_product_id: line_item.price.product)
        product.increment!(:sales_count)
      end
    when "customer.updated"
      @customer = Stripecustomer.update_stripe_customer(event)
      puts "Customer updated: #{@customer.email} // #{@customer.id} // #{event.id}}"
    when "customer.deleted"
      @customer = Stripecustomer.remove_stripe_customer(event)
      puts "Customer id remove for : #{@customer.email} // #{@customer.id}}"
    when "customer.subscription.created"
      @subscription = Stripesubscription.update_or_create(event)
      puts "Subscription created: #{event.id}"

    when "customer.subscription.updated"
      @subscription = Stripesubscription.update_or_create(event)
      puts "Subscription updated: #{event.id}"
    when "customer.subscription.deleted"
      stripe_subscription_id = event.data.object.id
      @subscription = Stripesubscription.delete(stripe_subscription_id)
      puts "Subscription deleted: #{event.id}"
    end

  # when "customer.subscription.updated"
  #     @subscription = Stripesubscription.update_for_customer(event)
  #     # handle subscription updated
  #     # puts data_object
  #     # binding.pry
  #     puts "Subscription updated: #{event.id}"
  #   end

    if event.type == ""
    end

    if event.type == "customer.subscription.trial_will_end"
      # handle subscription trial ending
      # puts data_object
      puts "Subscription trial will end: #{event.id}"
    end

    render json: { message: "success" }
  end
end
