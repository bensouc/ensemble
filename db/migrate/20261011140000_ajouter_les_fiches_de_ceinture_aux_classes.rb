# frozen_string_literal: true

# Les fiches de ceinture s'ouvrent classe par classe : le menu « Ceintures », les
# exercices de ceinture et la fiche d'un élève n'apparaissent que pour les
# classes qui l'ont choisi. Réglage de la classe — tous ses enseignants voient
# les mêmes élèves —, posé dans la modale où on la nomme.
#
# Coupé par défaut : rien ne change pour une classe tant que son enseignant ne
# l'a pas décidé.
class AjouterLesFichesDeCeintureAuxClasses < ActiveRecord::Migration[8.1]
  def change
    add_column :classrooms, :belt_sheets, :boolean, default: false, null: false
  end
end
