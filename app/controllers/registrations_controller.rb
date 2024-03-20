# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!
  skip_before_action :require_no_authentication, only: [:new, :create]

  def new
    if user_signed_in?
      super
    else
      redirect_to root_path, notice: "Vous n'avez pas les droits pour cela"
    end
  end

  def create
    @user = User.new(param_user)
    if user_signed_in?
      @user.school = current_user.school
      @user.demo = false
    else
      @user.school = School.find_by(name:"Ensemble / DEMO")
      @user.demo = true
    end
    if @user.save!
      if @user.demo?
        ContactMailer.new_demo_user(@user).deliver
        sign_in(@user)
        redirect_to dashboard_path, notice: "Utilisateur créé avec succès."
      else
        ContactMailer.add_user_to_school(@user).deliver
        redirect_to school_path(current_user.school), notice: "Utilisateur créé avec succès."
      end
    else
      flash.now[:alert] = "Une erreur est survenue lors de la création."
      render :new, status: :unprocessable_entity
    end
  end

  def after_update_path_for(_resource)
    dashboard_path
  end

  private

  def param_user
    params.required(:user).permit(:first_name, :last_name, :password, :email, :discovery_method)
  end
end
