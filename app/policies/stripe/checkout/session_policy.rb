class Stripe::Checkout::SessionPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end

  def subscription_checkout?
    true
  end
end
