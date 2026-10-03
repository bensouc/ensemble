class WorkPlanPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.includes([:student]).where(user:,
                                       special_wps: false).order(created_at: :DESC)
    end
  end

  def show?
    user_is_owner_or_admin?
  end

  # Un plan, fait main ou généré, pour un élève qu'on suit : ceux de ses classes
  # et des classes qu'un collègue partage, comme la modale de création rapide.
  # `true` laissait n'importe quel enseignant créer un plan pour l'élève d'une
  # autre école, en donnant son id.
  def create?
    user.admin? || record.student.nil? || user.all_students.include?(record.student)
  end

  def update?
    user_is_owner_or_admin?
  end

  def destroy?
    user_is_owner_or_admin?
  end

  def evaluation?
    user_is_owner_or_admin?
  end

  def auto_new_wp?
    create?
  end

  # Copier un plan, c'est le lire.
  def clone?
    show?
  end

  # `record` est la copie partagée : elle part chez un collègue de l'école, pas
  # chez n'importe quel compte désigné par son id.
  def share?
    user.admin? || user.collegues.include?(record.user)
  end

  private

  def user_is_owner_or_admin?
    user.admin || record.user.school == user.school
  end
end
