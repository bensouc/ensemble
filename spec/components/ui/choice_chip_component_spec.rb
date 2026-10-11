# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::ChoiceChipComponent, type: :component do
  it "rend un bouton radio dans sa pastille, avec l'icône de la ceinture" do
    chip = render_inline(described_class.new(name: "niveau", value: 3, label: "Orange", belt: 3, checked: true))

    radio = chip.at_css("label.ui-chip input[type=radio].ui-chip-input")
    expect(radio["name"]).to eq("niveau")
    expect(radio["value"]).to eq("3")
    expect(radio["checked"]).to be_present
    expect(radio["required"]).to be_present
    expect(chip.at_css(".ui-chip-body i.fa-bacon.belt-3")).to be_present
    expect(chip.at_css(".ui-chip-body").text.squish).to eq("Orange")
  end

  it "grise un choix impossible, et dit pourquoi" do
    chip = render_inline(described_class.new(name: "d", value: 1, label: "Calcul", hint: "toutes validées",
                                             disabled: true))

    expect(chip.at_css("label.ui-chip--disabled input")["disabled"]).to be_present
    expect(chip.at_css(".ui-chip-hint").text).to eq("toutes validées")
  end
end
