module Stripecustomer
  def self.add_stripe_customer(event)
    customer = event.data.object
    client = School.find_by(email: customer.email)
    client = User.find_by(email: customer.email) if client.nil?
    client&.update(stripe_customer_id: customer.id)
    customer
  end

  def self.remove_stripe_customer(event)
    customer = event.data.object
    # binding.pry
    client = School.find_by(email: customer.email)
    client = User.find_by(email: customer.email) if client.nil?
    client&.update(stripe_customer_id: nil)
    customer
  end

  def self.add_subscription_to_customer(event)
    binding.pry
    subscription = event.data.object
  end
end
