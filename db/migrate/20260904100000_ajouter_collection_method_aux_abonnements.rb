# frozen_string_literal: true

# Le mode de recouvrement Stripe de l'abonnement : `charge_automatically` ou
# `send_invoice`. L'app en a besoin parce que le portail client de Stripe ne sait
# PAS modifier un abonnement sur facture — le client peut seulement l'y annuler.
# Sans cette colonne, on proposait « Ajouter une classe à mon abonnement » à une
# école dont le portail ne sait que résilier.
#
# Laissé nul pour les lignes existantes : nul se comporte comme avant, le portail
# reste proposé. `bin/rails stripe:backfill_collection_method` le renseigne depuis
# Stripe, sans attendre le prochain événement d'abonnement.
class AjouterCollectionMethodAuxAbonnements < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :collection_method, :string
  end
end
