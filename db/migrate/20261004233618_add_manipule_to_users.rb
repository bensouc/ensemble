# frozen_string_literal: true

# Manipule est une option, pas une fonctionnalité de l'abonnement : on l'ouvre
# enseignant par enseignant, le temps de l'essai. Même forme que `demo`, qui
# marque déjà un compte à part sur cette table.
#
# Pas de reprise à faire : l'option est fermée pour tout le monde au départ,
# et c'est l'état voulu.
class AddManipuleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :manipule, :boolean, default: false, null: false
  end
end
