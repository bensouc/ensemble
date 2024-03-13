module Stripecustomer
  def self.add_stripe_customer(event)
    customer = event.data.object
    client = School.find_by(email: customer.email)
    client&.update(stripe_customer_id: customer.id)
    customer
  end

  def self.update_stripe_customer(event)
    customer = event.data.object
    client = School.find_by(email: customer.id)
    # RAF TO BE DONE LATER
    customer
  end

  def self.remove_stripe_customer(event)
    customer = event.data.object
    # binding.pry
    client = School.find_by(stripe_customer_id: customer.id)
    client = User.find_by(stripe_customer_id: customer.id) if client.nil?
    client&.update(stripe_customer_id: nil)
    customer
  end
end
