module Mobile::ClassroomsHelper
  # Même raison que `ClassroomsHelper#classes_label` : `pluralize` est sensible à
  # la locale, et aucune inflexion n'est définie pour le français — « 2 élève »
  # en sortait.
  def eleves_label(nombre)
    "#{nombre} élève#{'s' if nombre > 1}"
  end
end
