class SharedClassroomPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user.shared_classrooms
    end
  end

  # Partager sa classe, c'est ouvrir ses élèves : à un collègue de l'école, pas
  # à n'importe quel compte désigné par son id.
  def create?
    user_is_owner_or_admin? && (record.user.nil? || user.admin? || user.collegues.include?(record.user))
  end

  # Deux personnes peuvent défaire un partage : celle qui le subit, pour quitter
  # la classe, et le propriétaire, pour reprendre la sienne. Le contrôleur
  # autorisait la CLASSE et non le partage, si bien qu'un collègue pouvait retirer
  # le partage d'un autre collègue.
  def destroy?
    user_is_owner_or_admin? || record.user == user
  end

  private

  def user_is_owner_or_admin?
    user.admin? || record.classroom.user == user
  end
end
