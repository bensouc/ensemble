# frozen_string_literal: true

# Un professeur peut sortir un domaine de la génération automatique de SES plans
# de travail — la géométrie qu'il traite en classe entière, par exemple. C'est
# une préférence de l'enseignant et non un attribut du domaine : les domaines
# sont ceux de l'école, partagés entre collègues, et chacun mène sa classe.
#
# Une ligne = un domaine exclu. L'absence de ligne est le cas général : tous les
# domaines existants restent générés, rien à reprendre.
#
# Les clés étrangères cascadent : supprimer un domaine ou un compte emporte ses
# préférences, sans qu'aucun `destroy` n'ait à y penser.
class CreateAutoGenExclusions < ActiveRecord::Migration[8.1]
  def change
    create_table :auto_gen_exclusions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :domain, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :auto_gen_exclusions, [:user_id, :domain_id], unique: true
  end
end
