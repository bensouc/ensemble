# frozen_string_literal: true

# D'où vient un résultat : d'une évaluation de plan de travail, ou posé à la
# main depuis la grille de classe ou l'écran des ceintures.
#
# La distinction n'existait nulle part, et la grille de classe laissait donc
# supprimer d'un clic une ceinture que l'élève avait décrochée sur un exercice
# de ceinture — sans rien recalculer au passage.
#
# Le backfill rejoue l'inférence qui a servi à mesurer la population : un
# résultat de ceinture validée est dit « direct » quand aucun WPS de ceinture
# évalué `completed` ne lui correspond. Tout le reste vient du plan de travail,
# seul chemin qui écrive un résultat hors validation manuelle.
#
# `update_column` saute validations et callbacks — sans lui, chaque ligne
# relancerait la cascade des ceintures. Même motif que les migrations
# `position` qui précèdent (20240827135426, 20240910153715, 20260820100000).
class AjouterOrigineAuxResultats < ActiveRecord::Migration[7.1]
  def change
    add_column :results, :origin, :string

    Result.reset_column_information
    evaluees = WorkPlanSkill.joins(work_plan_domain: :work_plan).
               where(kind: "ceinture", status: "completed").
               pluck("work_plans.student_id", :skill_id).to_set

    Result.find_each do |result|
      posee_a_la_main = result.kind == "ceinture" && result.status == "completed" &&
                        !evaluees.include?([result.student_id, result.skill_id])
      result.update_column(:origin, posee_a_la_main ? "direct" : "evaluation")
    end
  end
end
