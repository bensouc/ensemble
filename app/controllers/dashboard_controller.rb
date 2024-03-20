# frozen_string_literal: true

class DashboardController < ApplicationController
  def show
    skip_authorization
    # STRIPE SWITCH OFF
    # stripe_customer = StripeHelper.get_or_create_customer(current_user.school)
    # session["stripe_customer"] = stripe_customer
    @has_classrooms = current_user.classroom?
    @has_work_plan = !current_user.work_plans.empty?
    @has_empty_classroom = !current_user.all_students.empty?
    # render "dashboard/show"
  end

  def add_discovery_method
    authorize current_user
    current_user.update(discovery_params)
    redirect_to dashboard_path
  end

  private
  def discovery_params
    params.require(:discovery_method).permit(:discovery_method)
  end
end
