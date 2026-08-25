# frozen_string_literal: true

# Invitation d'un collègue par le responsable du groupe. Le compte est rattaché
# à l'école dès l'envoi : l'invité n'a plus qu'à choisir son mot de passe.
#
# Remplace l'ancien chemin, où le responsable saisissait lui-même le mot de passe
# de son collègue et le recevait en clair par mail.
module Users
  class InvitationsController < Devise::InvitationsController
    # La gem renvoie sur la page vitrine avec « Le jeton d'invitation fourni n'est
    # pas valide ! », sans dire quoi faire. Deux causes courantes, et le jeton
    # effacé à l'acceptation ne permet pas de les distinguer : le compte a déjà
    # été créé, ou une invitation plus récente a remplacé ce lien. L'écran de
    # connexion sert les deux.
    LIEN_PERIME = "Ce lien d'invitation n'est plus valide. Si vous avez déjà créé votre compte, " \
                  "connectez-vous ci-dessous. Sinon, demandez une nouvelle invitation au " \
                  "responsable de votre groupe."

    # `edit` et `update` sont l'écran d'acceptation : l'invité n'est évidemment
    # pas connecté quand il clique dans son mail. Les deux actions viennent de
    # Devise::InvitationsController, que le cop ne remonte pas.
    # rubocop:disable Rails/LexicallyScopedActionFilter
    skip_before_action :authenticate_user!, only: [:edit, :update]
    # rubocop:enable Rails/LexicallyScopedActionFilter

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

    def resource_from_invitation_token
      return if params[:invitation_token].present? &&
                (self.resource = resource_class.find_by_invitation_token(params[:invitation_token], true))

      redirect_to new_user_session_path, alert: LIEN_PERIME
    end

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

    # L'adresse est la seule chose que le responsable ait vérifiée : c'est là
    # qu'il a envoyé l'invitation. La laisser changer ici, c'est permettre à qui
    # détient le lien d'inscrire l'adresse de son choix dans le groupe.
    #
    # Le champ figé du formulaire n'y suffisait pas : `Devise::BaseSanitizer`
    # n'existant plus en Devise 5, devise_invitable retombe sur une branche qui
    # AJOUTE ses clés aux défauts au lieu de les remplacer, et `email` s'y
    # retrouvait — un POST direct passait.
    #
    # L'invité change son adresse juste après, depuis « Mon compte », où Devise
    # exige son mot de passe.
    def update_resource_params
      super.except(:email)
    end

    # L'invité vient de choisir son mot de passe : il est connecté, autant
    # l'amener là où il a quelque chose à faire.
    def after_accept_path_for(_resource)
      dashboard_path
    end
  end
end
