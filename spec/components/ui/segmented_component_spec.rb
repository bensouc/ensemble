# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::SegmentedComponent, type: :component do
  it "pose un bouton radio par position, la position choisie cochée" do
    render_inline(described_class.new(name: "mode", checked: "b", label: "Choix",
                                      options: { "a" => "Première", "b" => "Seconde" }))

    expect(page).to have_css(".ui-segmented[role=radiogroup][aria-label=Choix]")
    expect(page).to have_css("input[type=radio][name=mode]", count: 2, visible: :all)
    expect(page).to have_css("input[value=b][checked]", visible: :all)
    expect(page).to have_css(".ui-segmented-label", text: "Première")
  end
end
