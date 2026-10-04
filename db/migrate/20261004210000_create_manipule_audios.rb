# frozen_string_literal: true

# L'audio des énoncés, pré-généré et rangé à côté d'eux.
#
# En base plutôt qu'en fichiers : une banque complète pèse une dizaine de
# mégaoctets, c'est de la donnée dérivée qu'on peut toujours refabriquer, et
# elle survit aux redéploiements sans stockage objet ni service tiers. Ça garde
# aussi la promesse de Manipule : supprimer la fonctionnalité, c'est supprimer
# ses tables.
#
# `texte_source` garde ce qui a RÉELLEMENT été dit : si l'enseignante corrige
# un énoncé, l'audio ne correspond plus et doit être refait. Sans cette colonne,
# un élève entendrait l'ancienne version sans que personne s'en aperçoive.
class CreateManipuleAudios < ActiveRecord::Migration[8.1]
  def change
    create_table :manipule_audios do |t|
      t.references :readable, polymorphic: true, null: false, index: false
      t.string :role, null: false
      t.text :texte_source, null: false
      t.string :content_type, null: false, default: "audio/mp4"
      t.binary :data, null: false
      t.string :voix
      t.integer :octets
      t.timestamps
      t.index %i[readable_type readable_id role], unique: true, name: "index_manipule_audios_sur_lu"
    end
  end
end
