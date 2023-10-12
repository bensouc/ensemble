module Stripecustomer
  def self.add_stripe_customer(event)
    customer = event.data.object
    client = School.find_by(email: customer.email)
    client = User.find_by(email: customer.email) if client.nil?
    client&.update(stripe_customer_id: customer.id)
    customer
  end
end
