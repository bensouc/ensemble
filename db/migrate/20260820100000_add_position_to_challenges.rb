# frozen_string_literal: true

# Ordre explicite des exercices au sein d'une compétence.
#
# La génération automatique tirait l'exercice au hasard (`challenges.sample`) :
# l'enseignant ne maîtrisait pas la progression. Elle prend désormais le premier
# exercice que l'élève n'a pas encore eu, dans cet ordre.
#
# Le backfill numérote à partir de 1, par couple (compétence, exercice de
# ceinture), dans l'ordre de rédaction. `update_column` saute validations et
# callbacks — même motif que les deux migrations `position` qui précèdent
# (20240827135426 pour les compétences, 20240910153715 pour les WPS).
class AddPositionToChallenges < ActiveRecord::Migration[7.1]
  def change
    add_column :challenges, :position, :integer
    add_index :challenges, %i[skill_id for_belt position]

    Challenge.reset_column_information
    Challenge.order(:created_at, :id).
      group_by { |challenge| [challenge.skill_id, challenge.for_belt] }.
      each_value do |challenges|
        challenges.each.with_index(1) { |challenge, index| challenge.update_column(:position, index) }
      end
  end
end
