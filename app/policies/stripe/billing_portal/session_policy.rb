class Stripe::BillingPortal::SessionPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end
   def create_portal_session?
    !record.nil?
  end
end
