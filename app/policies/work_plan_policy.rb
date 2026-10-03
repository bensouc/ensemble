class WorkPlanPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.includes([:student]).where(user:,
                                       special_wps: false).order(created_at: :DESC)
    end
  end

  # Le plan d'un élève se lit comme sa fiche : les profs de sa classe, ceux du
  # partage, les admins. Un plan sans élève — un modèle, à cloner — se lit dans
  # toute l'école.
  def show?
    return StudentPolicy.new(user, record.student).show? if record.student

    user.admin? || record.user.school == user.school
  end

  # Un plan, fait main ou généré, pour un élève qu'on suit : ceux de ses classes
  # et des classes qu'un collègue partage, comme la modale de création rapide.
  # `true` laissait n'importe quel enseignant créer un plan pour l'élève d'une
  # autre école, en donnant son id.
  #
  # Le niveau du plan, lui, doit être de son école ou de ses classes : `grade_id`
  # venait du formulaire, et un plan bâti sur le niveau d'une autre école en
  # tirait les domaines, les compétences et les exercices.
  def create?
    return true if user.admin?
    return false unless niveau_de_l_enseignant?

    record.student.nil? || user.all_students.include?(record.student)
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

  def niveau_de_l_enseignant?
    record.grade.nil? || record.grade.school == user.school || user.classroom_grades.include?(record.grade)
  end

  # Modifier, supprimer, évaluer un plan — y ajouter ou en retirer des
  # compétences : qui suit l'élève, soit les profs de sa classe, ceux du partage
  # et les admins. « Même école que l'auteur du plan » laissait n'importe quel
  # collègue intervenir sur les élèves d'une classe qu'il n'a pas. Un plan sans
  # élève reste à son auteur.
  def user_is_owner_or_admin?
    return StudentPolicy.new(user, record.student).update? if record.student

    user.admin? || record.user == user
  end
end
