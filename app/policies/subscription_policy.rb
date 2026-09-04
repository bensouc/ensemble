class SubscriptionPolicy < ApplicationPolicy
  # class Scope < Scope
  #   # NOTE: Be explicit about which records you allow access to!
  #   def resolve
  #     user.shared_classrooms
  #   end
  # end

  def school_pricing?
    true
  end

  def success?
    true
  end

  def on_boarding?
    user.admin? || user.demo? || user.school.valid_subscription?
  end

  # def new?
  #   create?
  # end

  def create?
    user.admin? || true
  end

  # Demander une modification d'abonnement engage la facturation du groupe :
  # c'est l'affaire du responsable. Les CTA qui y mènent sont déjà réservés à
  # lui — la route doit l'être aussi, sans quoi n'importe quel enseignant peut
  # nous demander de changer la quantité payée de son école.
  def change_request?
    user.admin? || user.super_teacher?
  end

  def create_change_request?
    change_request?
  end

  private

  def user_is_owner_or_admin?
    user.admin || record.classroom.user == user
  end
end
