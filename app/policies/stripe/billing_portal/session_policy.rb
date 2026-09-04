# frozen_string_literal: true

class Stripe::BillingPortal::SessionPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end

  # Le portail de facturation permet de **résilier** l'abonnement de l'école, et
  # d'en changer la quantité payée. C'est l'affaire du responsable, personne
  # d'autre.
  #
  # La règle était `!record.nil?`, donc toujours vraie : n'importe quel enseignant
  # connecté pouvait ouvrir `/create-customer-portal-session` et résilier
  # l'abonnement de son groupe. Le menu ne faisait que cacher le bouton.
  #
  # `admin?` n'ouvre PAS le portail : le compte de support n'a pas d'abonnement à
  # gérer, et `current_user.school` désignerait sa propre école de test. Pour
  # accompagner une école, un admin la personnifie — et doit désormais
  # personnifier **un responsable**, ce qui est aussi le compte que la démarche
  # concerne.
  def create_portal_session?
    user.super_teacher?
  end
end
