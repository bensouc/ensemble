# frozen_string_literal: true

class DashboardController < ApplicationController
  def show
    skip_authorization
    stripe_customer = StripeHelper.get_or_create_customer(current_user.school)
    session["stripe_customer"] = stripe_customer
    render "dashboard/show"
  end
end
