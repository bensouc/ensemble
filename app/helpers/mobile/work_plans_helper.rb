# frozen_string_literal: true

module Mobile::WorkPlansHelper
  # Même raison que `ClassroomsHelper#classes_label` : `pluralize` est sensible à
  # la locale et aucune inflexion n'est définie pour le français.
  def plans_label(nombre)
    "#{nombre} plan#{'s' if nombre > 1}"
  end
end
