# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!
  skip_before_action :require_no_authentication, only: [:new, :create]

  def new
    # if user_signed_in?
    #   super
    # else
    #   redirect_to root_path, notice: "Vous n'avez pas les droits pour cela"
    # end
  end

  def create
    # raise
    @user = User.new(param_user)
    @user.school = user_signed_in? ? current_user.school : School.find_by(name:"Ensemble / DEMO")
    @user.demo = true
    if @user.save!
      if @user.demo?
        ContactMailer.new_demo_user(@user).deliver
        sign_in(@user)
        redirect_to dashboard_path, notice: "Utilisateur créé avec succès."
      else
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
    params.required(:user).permit(:first_name, :last_name, :password, :email)
  end
end
