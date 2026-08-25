# frozen_string_literal: true

# La colonne portait « annuel » en minuscule comme valeur par défaut, alors que
# `Subscription` valide `inclusion: %w[Annuel Mensuel]` : toute création qui ne
# renseignait pas explicitement `rythm` était invalide — y compris depuis
# rails_admin, où le champ arrive pré-rempli avec ce défaut.
class CorrigerDefautRythmSubscription < ActiveRecord::Migration[7.1]
  def up
    change_column_default :subscriptions, :rythm, from: "annuel", to: "Annuel"
    Subscription.reset_column_information
    Subscription.where(rythm: "annuel").find_each { |s| s.update_column(:rythm, "Annuel") }
  end

  def down
    change_column_default :subscriptions, :rythm, from: "Annuel", to: "annuel"
  end
end
