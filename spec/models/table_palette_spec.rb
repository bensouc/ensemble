# frozen_string_literal: true

require "rails_helper"

# La palette de couleurs du texte existe des deux côtés : `Table::TEXT_COLORS`
# alimente la barre du tableau (rendue par Rails), `TEXT_SWATCHES` alimente le
# nuancier de la toolbar principale (construit en JS).
#
# Les fusionner demanderait de faire transiter la liste par le DOM jusqu'à
# `getDefaultHTML`, qui s'exécute avant tout rendu — un couplage plus coûteux
# que le problème. On garde donc les deux sources, avec ce contrôle : sans lui,
# ajouter une teinte d'un seul côté donne un éditeur qui propose deux palettes
# différentes selon qu'on est dans une cellule ou dans le corps de l'énoncé,
# sans erreur ni signal.
RSpec.describe "Palette de couleurs du texte" do
  let(:javascript) { Rails.root.join("app/javascript/plugins/trix-config.js").read }

  it "est identique côté Ruby et côté JavaScript" do
    swatches = javascript[/const TEXT_SWATCHES = \[$(.*?)^\]/m, 1]
    expect(swatches).to be_present, "TEXT_SWATCHES introuvable dans trix-config.js"

    expect(swatches.scan(/"(#[0-9A-Fa-f]{6})"/).flatten.map(&:upcase)).to eq(Table::TEXT_COLORS)
  end

  it "n'expose que des hexadécimaux à six chiffres" do
    # Les teintes sont écrites dans un attribut `style` : le modèle n'accepte
    # que cette liste, elle doit donc rester une liste de valeurs inertes.
    expect(Table::TEXT_COLORS).to all(match(/\A#[0-9A-F]{6}\z/))
  end
end
