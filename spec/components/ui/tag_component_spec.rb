# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::TagComponent, type: :component do
  it "pose le mot dans une pastille" do
    page = render_inline(described_class.new("Fiche de ceinture"))

    expect(page.at_css("span.ui-tag").text).to eq("Fiche de ceinture")
    expect(page.at_css(".ui-tag-pastille")).to be_nil
  end

  it "met un embout de couleur devant le mot" do
    page = render_inline(described_class.new("En cours", pastille: "belt-bg-3"))

    expect(page.at_css("span.ui-tag").text).to eq("En cours")
    expect(page.at_css("span.ui-tag > span.ui-tag-pastille.belt-bg-3")["aria-hidden"]).to eq("true")
  end
end
