# frozen_string_literal: true

require "rails_helper"

# Le bouton « Accéder aux tutos » de la page d'accueil. Son URL était recopiée
# dans la vue, sous la forme que Notion donne dans la barre d'adresse : celle
# qui porte le titre de la page et meurt au premier renommage. Elle passe
# désormais par la constante — ce spec tient la destination, pas l'écriture.
RSpec.describe "pages/_details", type: :view do
  it "mène au sommaire des tutos" do
    render partial: "pages/details"

    expect(rendered).to include("href=\"#{ApplicationHelper::TUTO_SOMMAIRE}\"")
    expect(rendered).to include("Accéder aux tutos")
  end
end
