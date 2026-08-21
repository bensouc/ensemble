# frozen_string_literal: true

# Naviguer dans l'app sous l'identité d'un enseignant, pour reproduire ce qu'il
# voit. L'admin ne se déconnecte jamais : Warden garde son compte, la gem
# `pretender` dévie seulement `current_user` (l'admin reste `true_user`).
class ImpersonationsController < ApplicationController
  def index
    authorize :impersonation, :index?
    # La policy ci-dessus EST le périmètre : un admin voit tous les comptes.
    skip_policy_scope
    @users_by_school = users_grouped_by_school
  end

  def create
    user = User.find(params[:user_id])
    authorize user, :create?, policy_class: ImpersonationPolicy
    impersonate_user(user)
    log_impersonation("début", user)
    redirect_to dashboard_path,
                notice: "Vous naviguez maintenant en tant que #{user.first_name} #{user.last_name}."
  end

  def destroy
    authorize :impersonation, :destroy?
    log_impersonation("fin", current_user) if impersonating?
    stop_impersonating_user
    redirect_to impersonations_path, notice: "Vous êtes revenu sur votre compte."
  end

  private

  # Dans ce contrôleur, l'acteur est le vrai utilisateur et pas celui qu'on
  # incarne : c'est ce qui permet d'arrêter la personnification, ou d'en changer,
  # sans repasser par son propre compte.
  def pundit_user
    true_user
  end

  # Les comptes sans `school_role` existent (inscription abandonnée avant la
  # création de l'école) : ils forment un groupe à part plutôt que de disparaître.
  def users_grouped_by_school
    User.where(admin: false).
      includes(:avatar_attachment, school_role: :school).
      order(:first_name, :last_name).
      group_by { |user| user.school_role&.school }.
      sort_by { |school, _users| [school ? 0 : 1, school&.name.to_s.downcase] }
  end

  # Pas de table d'audit dans cette app : la trace vit dans les logs, avec le
  # vrai auteur de la bascule.
  def log_impersonation(step, target)
    Rails.logger.warn(
      "[personnification] #{step} — #{true_user.email} (##{true_user.id}) " \
      "→ #{target.email} (##{target.id})"
    )
  end
end
