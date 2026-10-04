# frozen_string_literal: true

require "rails_helper"

# Le bouton d'envoi de la modale de génération, sur la fiche élève : ses
# attributs `data` branchent le rouage d'attente.
RSpec.describe Btns::ValidateComponent, type: :component do
  it "rend un bouton d'envoi avec ses classes et ses attributs data" do
    bouton = render_inline(described_class.new(
                             btn_text: "Valider",
                             btn_class: "ensemble-bouton --bgc-vert --blanc",
                             btn_data: { controller: "loadingspinnermgnt",
                                         action: "click->loadingspinnermgnt#addSpinner" }
                           )).at_css("button")

    expect(bouton["type"]).to eq("submit")
    expect(bouton["class"]).to eq("ensemble-bouton --bgc-vert --blanc")
    expect(bouton["data-controller"]).to eq("loadingspinnermgnt")
    expect(bouton["data-action"]).to eq("click->loadingspinnermgnt#addSpinner")
    expect(bouton.text.strip).to eq("Valider")
  end

  # Le libellé passe par `raw` : il peut porter une icône.
  it "laisse passer le HTML du libellé" do
    bouton = render_inline(described_class.new(btn_text: '<i class="fa-solid fa-check"></i> Valider',
                                               btn_class: "ensemble-bouton")).at_css("button")

    expect(bouton.at_css("i.fa-check")).to be_present
  end
end
