# frozen_string_literal: true

# Les annonces qu'un compte a choisi de ne plus voir (« Ne plus afficher »).
# Retenues sur le compte, pas dans le navigateur : un professeur·e qui change
# d'ordinateur ne revoit pas une annonce qu'il a écartée.
class AjouterLesAnnoncesMasqueesAuxComptes < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :annonces_masquees, :string, array: true, default: [], null: false
  end
end
