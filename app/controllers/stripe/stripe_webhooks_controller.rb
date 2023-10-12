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
        payload, sig_header, ENV["LOCAL_STRIPE_WEBHOOK_SECRET_KEY"]
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
    when "customer.created"
      @customer = Stripecustomer.add_stripe_customer(event)
      puts "Customer created: #{@customer.email} // #{@customer.id} // #{event.id}}"
    end

    if event.type == "customer.subscription.deleted"
      # handle subscription canceled automatically based
      # upon your subscription settings. Or if the user cancels it.
      # puts data_object
      puts "Subscription canceled: #{event.id}"
    end

    if event.type == "customer.subscription.updated"
      # handle subscription updated
      # puts data_object
      puts "Subscription updated: #{event.id}"
    end

    if event.type == "customer.subscription.created"
      # handle subscription created
      # puts data_object
      puts "Subscription created: #{event.id}"
    end

    if event.type == "customer.subscription.trial_will_end"
      # handle subscription trial ending
      # puts data_object
      puts "Subscription trial will end: #{event.id}"
    end

    render json: { message: "success" }
  end
end
