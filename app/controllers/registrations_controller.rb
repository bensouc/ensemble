# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!
  skip_before_action :require_no_authentication, only: [:new, :create]

  # Ajouter un collègue passe désormais par l'invitation : il choisit son mot de
  # passe lui-même. Ici, le responsable le saisissait à sa place et le collègue
  # le recevait en clair par mail (ContactMailer#add_user_to_school).
  # La branche publique — création d'un compte de démonstration — est inchangée.
  def new
    return redirect_to new_user_invitation_path if user_signed_in?

    redirect_to root_path, notice: "Vous n'avez pas les droits pour cela"
  end

  def create
    return redirect_to new_user_invitation_path if user_signed_in?

    @user = User.new(param_user)
    @user.school = School.find_by(name: "Ensemble / DEMO")
    @user.demo = true

    if verify_recaptcha && @user.save
      ContactMailer.new_demo_user(@user).deliver
      sign_in(@user)
      redirect_to dashboard_path, notice: "Utilisateur créé avec succès."
    else
      flash.now[:alert] = "Une erreur est survenue lors de la création."
      redirect_to new_user_session_path, status: :unprocessable_content
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
