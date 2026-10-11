# frozen_string_literal: true

# La fiche de ceinture d'un élève : des blocs (un domaine à une couleur de
# ceinture), chacun portant ses compétences et l'exercice de ceinture donné pour
# chacune. Elle se prépare depuis la fiche de l'élève et s'imprime à part.
#
# Elle n'évalue rien : la réussite d'une ceinture se saisit toujours dans le
# plan de travail. D'où trois tables à elle plutôt que celles du plan, dont
# chaque ligne réécrit le `Result` de l'élève en s'enregistrant.
#
# Les clés étrangères cascadent : supprimer un élève, un domaine ou une
# compétence emporte ce qui en dépend, sans qu'aucun `destroy` n'ait à y penser.
# Un exercice supprimé laisse sa ligne sans exercice, à recharger.
class CreateBeltSheets < ActiveRecord::Migration[8.1]
  def change
    create_table :belt_sheets do |t|
      t.references :student, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, foreign_key: { on_delete: :nullify }

      t.timestamps
    end

    create_table :belt_sheet_domains do |t|
      t.references :belt_sheet, null: false, foreign_key: { on_delete: :cascade }
      t.references :domain, null: false, foreign_key: { on_delete: :cascade }
      t.integer :level, null: false

      t.timestamps
    end
    add_index :belt_sheet_domains, [:belt_sheet_id, :domain_id, :level], unique: true,
                                                                         name: "index_belt_sheet_domains_unique"

    create_table :belt_sheet_skills do |t|
      t.references :belt_sheet_domain, null: false, foreign_key: { on_delete: :cascade }
      t.references :skill, null: false, foreign_key: { on_delete: :cascade }
      t.references :challenge, foreign_key: { on_delete: :nullify }
      t.integer :position

      t.timestamps
    end
    add_index :belt_sheet_skills, [:belt_sheet_domain_id, :skill_id], unique: true
  end
end
