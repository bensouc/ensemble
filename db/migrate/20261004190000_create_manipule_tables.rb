# frozen_string_literal: true

# Le socle de Manipule, l'atelier d'entraînement autocorrigé de l'élève.
#
# Tout est additif : aucune table existante n'est touchée. Les problèmes
# s'accrochent aux `skills`, qui portent déjà leur niveau de ceinture de 1 à 7 et
# leur chaîne vers le domaine, le niveau de classe et l'école — rien à
# redéclarer. Supprimer Manipule, c'est supprimer ces six tables et le dossier
# app/models/manipule, sans rien laisser derrière.
#
# D'où aussi le jeton de classe dans sa propre table plutôt qu'en colonne sur
# `classrooms` : une colonne nullable de plus serait sans danger, mais elle
# casserait cette propriété.
class CreateManipuleTables < ActiveRecord::Migration[8.1]
  def change
    create_table :manipule_problems do |t|
      # L'index composite ci-dessous couvre déjà skill_id seul, en préfixe.
      t.references :skill, null: false, foreign_key: true, index: false
      # L'auteur survit à la suppression de son compte, comme pour les exercices.
      t.references :user, foreign_key: true
      t.text :statement, null: false
      t.string :question, null: false
      t.string :answer_mode, null: false, default: "choix"
      t.string :answer
      t.string :unit
      t.string :tool
      # Les nombres de l'énoncé et les réglages de l'outil. Sans eux, « 15 pommes »
      # n'existe que dans la phrase et aucun outil ne peut s'afficher.
      t.jsonb :tool_data, null: false, default: {}
      t.boolean :published, null: false, default: false
      t.integer :position
      t.timestamps
      t.index %i[skill_id published]
    end

    create_table :manipule_choices do |t|
      t.references :problem, null: false, foreign_key: { to_table: :manipule_problems }
      t.string :label, null: false
      t.boolean :correct, null: false, default: false
      t.integer :position
      t.timestamps
    end

    create_table :manipule_assignments do |t|
      t.references :student, null: false, foreign_key: true, index: false
      t.references :skill, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :active, null: false, default: true
      t.timestamps
      t.index %i[student_id active]
    end

    create_table :manipule_practices do |t|
      t.references :student, null: false, foreign_key: true, index: false
      # La compétence est recopiée ici : une affectation change, l'historique non.
      t.references :skill, null: false, foreign_key: true
      t.integer :size, null: false, default: 10
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.timestamps
      t.index %i[student_id created_at]
    end

    create_table :manipule_attempts do |t|
      t.references :practice, null: false, foreign_key: { to_table: :manipule_practices }, index: false
      t.references :problem, null: false, foreign_key: { to_table: :manipule_problems }
      t.references :choice, foreign_key: { to_table: :manipule_choices }
      t.string :given
      # « passé » n'est pas « faux » : les confondre ferait mentir le suivi de
      # l'enseignante, qui verrait un échec là où il y a eu un renoncement.
      t.string :status, null: false, default: "pending"
      # Un élève qui réécoute cinq fois chaque énoncé ne bute pas sur les
      # mathématiques, il bute sur la lecture. La donnée ne coûte rien.
      t.integer :listened_count, null: false, default: 0
      t.integer :elapsed_ms
      t.datetime :answered_at
      t.integer :position, null: false
      t.timestamps
      t.index %i[practice_id position], unique: true
    end

    create_table :manipule_classroom_tokens do |t|
      t.references :classroom, null: false, foreign_key: true, index: { unique: true }
      t.string :token, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
