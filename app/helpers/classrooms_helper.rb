# frozen_string_literal: true

module ClassroomsHelper
  # Libellé d'une classe d'accueil dans la liste de transfert :
  # "CE1 Étoiles — CE1 — Sophie, Marc"
  # Le nom de la classe n'est pas répété quand il est identique au niveau.
  def classroom_transfer_label(classroom)
    teachers = classroom.teachers.filter_map { |teacher| teacher.first_name.presence&.capitalize }

    parts = [classroom.safe_name]
    parts << classroom.grade.name unless classroom.grade.name == classroom.safe_name
    parts << teachers.join(", ") if teachers.any?
    parts.join(" — ")
  end
end
