class ClassroomPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user.classrooms
    end
  end

  def create?
    # test demo, return true if authorize
    user_is_owner_or_admin? && create_classroom_demo? && sub_limit?
  end

  def results?
    user_is_owner_or_admin?
  end

  def results_by_domain?
    user_is_owner_or_admin?
  end

  def destroy?
    user_is_owner_or_admin?
  end

  def show?
    user_is_owner_or_admin?
  end

  def generate_pdfs?
    user_is_owner_or_admin?
  end

  def download_pdfs?
    user_is_owner_or_admin? && record.results_pdf_exists?
  end

  private

  # `user.admin? || user.demo ? … : true` se lisait `(admin? || demo) ? … : true` :
  # l'admin tombait dans la branche démo et restait plafonné à une seule classe.
  def create_classroom_demo?
    return true if user.admin?
    return true unless user.demo?

    user.classrooms.count < User::DEMO_CLASSROOM_LIMIT
  end

  # Deux corrections ici :
  # - le quota se compare au nombre de classes DÉJÀ créées, donc en `<` : avec
  #   `quantity >= count`, une école qui payait 3 classes en obtenait 4 ;
  # - le statut compte autant que le nombre. `subscription.nil?` laissait passer
  #   une ligne `canceled` ou `unpaid` : seule la suppression de l'abonnement
  #   fermait l'accès, jamais sa résiliation.
  #
  # Le décompte est celui qu'affiche la page École (`classrooms_total`), donc
  # hors classes des admins : les deux chiffres ne coïncidaient pas.
  def sub_limit?
    return true if user.admin? || user.demo?

    school = user.school
    return false if school.nil? || !school.valid_subscription?

    school.classrooms_total < school.subscription.quantity.to_i
  end

  def user_is_owner_or_admin?
    user.admin? || record.user == user || record.shared_classrooms.any? do |shared_classroom|
      shared_classroom.user == user
    end
  end
end
