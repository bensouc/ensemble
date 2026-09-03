# frozen_string_literal: true

# Trois validations d'unicité tenaient seules depuis toujours : le nom d'un
# domaine dans son niveau, celui d'un exercice dans sa compétence, celui d'un
# niveau dans son école. Une validation ne voit que sa propre transaction :
# deux requêtes simultanées — un double-clic suffit — passent toutes les deux et
# insèrent le doublon. C'est d'autant plus vrai depuis que ces trois échecs
# renvoient enfin un message à l'enseignant (PR #455 et #456) : il va réessayer.
#
# Inventaire fait en prod le 03/09/2026 avant de poser les index : 0 doublon
# exact sur les trois couples, 0 nom vide ou NULL. Rien à nettoyer.
#
# `add_index` simple et non `algorithm: :concurrently` : les tables comptent
# 91 domaines, 2921 exercices et 15 niveaux. La pose se joue en millisecondes,
# alors qu'un index concurrent interdit la transaction et peut laisser un index
# INVALID derrière lui s'il échoue. Le lock ne vaut la peine d'être évité qu'à
# une tout autre échelle.
class IndexerUniciteDesNoms < ActiveRecord::Migration[7.1]
  def change
    add_index :domains, [:grade_id, :name], unique: true
    add_index :challenges, [:skill_id, :name], unique: true
    add_index :grades, [:school_id, :name], unique: true
  end
end
