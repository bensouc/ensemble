# frozen_string_literal: true

# Manipule s'accroche aux tables d'Ensemble — `students`, `classrooms`,
# `skills`, `users` — et rien, côté Ensemble, ne sait qu'il existe. C'était le
# but : tout est additif, aucun modèle d'Ensemble n'est touché.
#
# Mais une clef étrangère sans `on_delete` BLOQUE la suppression du parent. En
# l'état, supprimer une classe — une fonction documentée d'Ensemble — levait
# une erreur dès qu'un de ses élèves avait ouvert Manipule une fois. On
# déclare donc ce qui doit arriver, du côté de Manipule et de lui seul.
#
# `cascade` partout, sauf l'auteur d'un problème : sa colonne est volontairement
# nullable, parce qu'un problème survit au départ de celle qui l'a écrit, comme
# les exercices d'Ensemble.
class CascaderLesClesDeManipule < ActiveRecord::Migration[8.1]
  CASCADES = [
    [:manipule_assignments, :students, nil],
    [:manipule_assignments, :skills, nil],
    [:manipule_assignments, :users, nil],
    [:manipule_practices, :students, nil],
    [:manipule_practices, :skills, nil],
    [:manipule_problems, :skills, nil],
    [:manipule_classroom_tokens, :classrooms, nil],
    [:manipule_choices, :manipule_problems, :problem_id],
    [:manipule_attempts, :manipule_practices, :practice_id],
    [:manipule_attempts, :manipule_problems, :problem_id],
    [:manipule_attempts, :manipule_choices, :choice_id]
  ].freeze

  def up
    CASCADES.each { |table, cible, colonne| redeclarer(table, cible, colonne, :cascade) }
    redeclarer(:manipule_problems, :users, nil, :nullify)
  end

  def down
    CASCADES.each { |table, cible, colonne| redeclarer(table, cible, colonne, nil) }
    redeclarer(:manipule_problems, :users, nil, nil)
  end

  private

  def redeclarer(table, cible, colonne, action)
    options = colonne ? { column: colonne } : {}
    remove_foreign_key table, cible, **options
    add_foreign_key table, cible, **options, on_delete: action
  end
end
