# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::OptionCardComponent, type: :component do
  it "rend un bouton radio en carte, son titre et ce qu'il donne" do
    carte = render_inline(described_class.new(name: "mode", value: "en_cours", checked: true,
                                              title: "Ses ceintures en cours", text: "Ce qui est posé."))

    radio = carte.at_css("label.ui-option input[type=radio][name=mode]")
    expect(radio["value"]).to eq("en_cours")
    expect(radio["checked"]).to be_present
    expect(carte.at_css(".ui-option-title").text).to eq("Ses ceintures en cours")
    expect(carte.at_css(".ui-option-text").text).to eq("Ce qui est posé.")
  end
end
