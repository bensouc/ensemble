# frozen_string_literal: true

# Un domaine rangé pour Manipule et invisible d'Ensemble : il ne doit
# apparaître ni dans la progression d'un élève, ni dans la grille de ceintures,
# ni dans la génération des plans de travail.
#
# Le drapeau est porté par `domains` plutôt que par une table à part : un
# domaine de Manipule reste un domaine — il a son niveau, ses compétences et
# leurs ceintures, et c'est précisément ce qu'on veut en réutiliser.
#
# `default: false` suffit à reprendre l'existant : tous les domaines déjà en
# base sont ceux d'Ensemble.
class AjouterLeDrapeauManipuleAuxDomaines < ActiveRecord::Migration[8.1]
  def change
    add_column :domains, :manipule, :boolean, default: false, null: false
    add_index :domains, [:grade_id, :manipule]
  end
end
