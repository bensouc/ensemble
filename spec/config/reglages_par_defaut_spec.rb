# frozen_string_literal: true

require "rails_helper"

# Les réglages par défaut ont manqué pendant des années sans qu'aucune spec le
# voie (`load_defaults` n'était pas appelé) : on fixe ici la version chargée et
# la seule surcharge, définitive.
RSpec.describe "Réglages par défaut de Rails" do
  it "charge ceux de Rails 8.1" do
    expect(Rails.application.config.loaded_config_version.to_s).to eq("8.1")
  end

  # Changer la dérivation de clé casserait tout ce qui est signé : sgid des
  # tableaux et des images des exercices, URL Active Storage écrites dans les
  # textes, cookies.
  it "garde la dérivation de clé en SHA1" do
    expect(Rails.application.config.active_support.key_generator_hash_digest_class).to eq(OpenSSL::Digest::SHA1)
  end
end
