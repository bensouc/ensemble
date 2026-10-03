class SkillPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.includes([:challenges, :school]).where(domain: @domain)
    end
  end

  # Une compétence appartient à son école par deux chemins, `school` et son
  # domaine (`domain.grade.school`) : les deux doivent désigner l'école de
  # l'enseignant. Le domaine venait du formulaire sans contrôle, et une
  # compétence créée sous le domaine d'une autre école s'affichait chez elle.
  def create?
    user.admin? || (user_is_owner_or_admin? && record.domain&.grade&.school == user.school)
  end

  def show?
    user_is_owner_or_admin?
  end

  def edit?
    user_is_owner_or_admin?
  end

  def update?
    user_is_owner_or_admin?
  end

  def destroy?
    user_is_owner_or_admin?
  end

  def upload_skills_xlsx?
    !user.demo?
  end

  def add_skills_from_xls?
    upload_skills_xlsx?
  end

  def move?
    user_is_owner_or_admin?
  end

  private

  def user_is_owner_or_admin?
    user.admin || record.school == user.school
  end
end
