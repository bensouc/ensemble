# frozen_string_literal: true

# Un exercice survit au départ de son auteur : ce qui le rattache à l'école est
# son grade, via la compétence (`skill → domain → grade`), pas la personne qui
# l'a écrit. La suppression d'un compte coupe donc le lien plutôt que de céder
# les exercices à un « super teacher » — cession qui échouait dès que le
# repreneur désigné était le partant lui-même, et bloquait alors la suppression
# sur la clé étrangère `challenges.user_id`.
class RendreAuteurExerciceOptionnel < ActiveRecord::Migration[7.1]
  def change
    change_column_null :challenges, :user_id, true
  end
end
