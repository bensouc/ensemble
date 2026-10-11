# frozen_string_literal: true

# « Espace professeur.e », sur l'écran des prénoms, ramène à Ensemble : un élève
# qui le trouve quitte le jeu. L'enseignante peut désormais le fermer par un
# code, réglé dans Manipule pour chaque classe. Seule son empreinte (bcrypt) est
# gardée.
#
# Sans code — le cas de toutes les classes existantes —, la porte reste libre.
class AjouterLeCodeProfAuxJetonsDeClasse < ActiveRecord::Migration[8.1]
  def change
    add_column :manipule_classroom_tokens, :code_prof_digest, :string
  end
end
