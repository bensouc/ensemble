# frozen_string_literal: true

module Manipule
  # L'ouverture de l'option Manipule, compte par compte.
  #
  # Sans écran, il fallait passer par rails_admin ou par la console pour
  # donner l'accès à un testeur — donc demander à quelqu'un qui sait.
  class AccesController < ProfController
    before_action :exiger_un_admin

    # Sans recherche, on ne liste que les comptes déjà ouverts. Déverser
    # l'annuaire entier ne rendrait service à personne : ce qu'on vient
    # vérifier ici, c'est qui a l'option, et on cherche par le nom quand on
    # veut l'ouvrir à quelqu'un de précis.
    def index
      @recherche = params[:q].to_s.strip
      portee = policy_scope(User, policy_scope_class: AccesPolicy::Scope).includes(:school)
      @utilisateurs = (@recherche.present? ? chercher(portee, @recherche) : portee.where(manipule: true)).
        order(:email).limit(LIMITE)
      @ouverts = policy_scope(User, policy_scope_class: AccesPolicy::Scope).where(manipule: true).count
    end

    def update
      utilisateur = User.find(params[:id])
      authorize utilisateur, :update?, policy_class: AccesPolicy
      ouvert = ActiveModel::Type::Boolean.new.cast(params[:manipule])
      utilisateur.update!(manipule: ouvert)
      redirect_back_or_to manipule_acces_path,
                          notice: t("manipule.option_#{ouvert ? 'ouverte' : 'fermee_a'}",
                                    email: utilisateur.email)
    end

    LIMITE = 50

    private

    def chercher(portee, terme)
      motif = "%#{terme.downcase}%"
      portee.where(
        "lower(email) LIKE :motif OR lower(first_name) LIKE :motif OR lower(last_name) LIKE :motif",
        motif:
      )
    end

    def exiger_un_admin
      return if current_user&.admin?

      redirect_to manipule_root_path, alert: t("manipule.reserve_aux_admins")
    end
  end
end
