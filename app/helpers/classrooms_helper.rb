# frozen_string_literal: true

module ClassroomsHelper
  # Libellé d'une classe d'accueil dans la liste de transfert :
  # "CE1 Étoiles — CE1 — Sophie, Marc"
  def classroom_transfer_label(classroom)
    teachers = classroom.teachers.filter_map { |teacher| teacher.first_name.presence&.capitalize }

    [classroom.safe_name, classroom.grade.name, teachers.join(", ").presence].uniq.compact.join(" — ")
  end
end
