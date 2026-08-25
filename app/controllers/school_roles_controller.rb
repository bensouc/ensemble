class SchoolRolesController < ApplicationController
  # Un compte démo qui saisit le code d'une école bascule ici : il quitte l'école
  # de démonstration pour la vraie, et cesse d'être un compte démo.
  def create
    authorize SchoolRole
    code = School.normalize_code(params.dig(:new_sub, :school_code))
    # `find_by(code: nil)` aurait désigné n'importe quelle école dont le code
    # manque encore : une saisie vide ne cherche rien du tout.
    school = code && School.find_by(code:)

    # Sans ce garde-fou, `authorize nil` levait une Pundit::NotDefinedError :
    # une faute de frappe sur le code répondait par une erreur 500.
    if school.nil?
      redirect_to join_school_path,
                  alert: "Code école inconnu. Vérifiez-le auprès du responsable du groupe."
      return
    end

    join(school)
    redirect_to dashboard_path, notice: "Vous avez rejoint l'école/groupe #{school.name}."
  end

  private

  # `add_teacher` remplace le school_role existant au lieu d'en empiler un
  # second : `has_one :school_role` en aurait désigné un au hasard, et
  # l'enseignant se serait retrouvé dans l'école de démonstration une fois sur deux.
  def join(school)
    school.add_teacher(current_user)
    current_user.update(demo: false)
  end
end
