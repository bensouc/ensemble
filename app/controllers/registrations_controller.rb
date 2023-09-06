# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!
  skip_before_action :require_no_authentication, only: [:new, :create]

  def new
    if user_signed_in?
      super
    else
      redirect_to root_path, notice: "Vous n'avez pas les autorisations pour cette action"
    end
  end

  def create
    @user = User.new(param_user)
    @user.school = user_signed_in? ? current_user.school : School.where { |s| s.name == "Ensemble" }
    if @user.save!
      redirect_to school_path(current_user.school), notice: "Utilisateur créé avec succès."
    else
      flash.now[:alert] = "Une erreur est survenue lors de la création."
      render :new
    end
  end

  private

  def param_user
    params.required(:user).permit(:first_name, :last_name, :password, :email)
  end
end
