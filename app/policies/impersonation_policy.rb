# frozen_string_literal: true

# `user` est ici le VRAI utilisateur (voir `ImpersonationsController#pundit_user`) :
# sans ça, un admin en pleine personnification — dont le `current_user` est
# l'enseignant incarné — n'aurait plus le droit d'en sortir.
class ImpersonationPolicy < ApplicationPolicy
  def index?
    admin?
  end

  # Ni soi-même (sans effet), ni un autre admin : le jour où il y aura plusieurs
  # comptes admin, personnifier l'un d'eux serait un chemin d'escalade.
  def create?
    admin? && record.is_a?(User) && record != user && !record.admin?
  end

  def destroy?
    admin?
  end

  private

  def admin?
    user&.admin? == true
  end
end
