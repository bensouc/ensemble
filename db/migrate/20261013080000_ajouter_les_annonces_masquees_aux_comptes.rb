# frozen_string_literal: true

# Ce que chaque compte a fait des annonces du tableau de bord (voir Annonce) :
#
#   - `annonces_masquees` : celles écartées pour de bon (« Ne plus afficher ») ;
#   - `annonces_reportees` : celles remises au lendemain (« Plus tard »), avec le
#     jour du clic — { "nouvel-editeur-2026-10" => "2026-10-13" }.
#
# Retenues sur le compte, pas dans le navigateur : changer d'ordinateur ne fait
# pas revenir une annonce écartée ou reportée.
class AjouterLesAnnoncesMasqueesAuxComptes < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :annonces_masquees, :string, array: true, default: [], null: false
    add_column :users, :annonces_reportees, :jsonb, default: {}, null: false
  end
end
