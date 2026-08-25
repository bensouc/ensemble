# frozen_string_literal: true

# Invitation d'un collègue par le responsable du groupe. Le compte est rattaché
# à l'école dès l'envoi : l'invité n'a plus qu'à choisir son mot de passe.
#
# Remplace l'ancien chemin, où le responsable saisissait lui-même le mot de passe
# de son collègue et le recevait en clair par mail.
module Users
  class InvitationsController < Devise::InvitationsController
    # `edit` et `update` sont l'écran d'acceptation : l'invité n'est évidemment
    # pas connecté quand il clique dans son mail.
    skip_before_action :authenticate_user!, only: [:edit, :update]

    def new
      inviting_school
      super
    end

    def create
      school = inviting_school
      self.resource = school.invite_teacher(invite_params[:email], current_user)

      if resource.errors.empty?
        redirect_to school_path(school), notice: "Invitation envoyée à #{resource.email}."
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    # `authorize(nil)` lèverait une Pundit::NotDefinedError, donc une 500 : un
    # compte sans école n'a personne à inviter, c'est un refus, pas une panne.
    def inviting_school
      @inviting_school ||= begin
        school = current_user.school
        raise Pundit::NotAuthorizedError, "compte sans école" if school.nil?

        authorize(school, :invite_teacher?)
      end
    end

    def invite_params
      params.require(:user).permit(:email)
    end

    # L'invité vient de choisir son mot de passe : il est connecté, autant
    # l'amener là où il a quelque chose à faire.
    def after_accept_path_for(_resource)
      dashboard_path
    end
  end
end
