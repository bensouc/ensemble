# frozen_string_literal: true

class DashboardController < ApplicationController
  def show
    stripe_customer = StripeHelper.get_or_create_customer(current_user)
    session["stripe_cutomer"] = stripe_customer
    render "dashboard/show"
  end
end
