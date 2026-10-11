# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::TabsComponent, type: :component do
  it "rend un lien par onglet, et marque celui de la page courante" do
    nav = render_inline(described_class.new(label: "Exercices", tabs: [
                                              { label: "Exercices", href: "/challenges", active: true },
                                              { label: "Exercices de ceinture", href: "/challenges?ceinture=1" }
                                            ])).at_css("nav.ui-tabs")

    expect(nav["aria-label"]).to eq("Exercices")
    liens = nav.css("li a")
    expect(liens.map(&:text)).to eq(["Exercices", "Exercices de ceinture"])
    expect(liens.first["class"]).to eq("ui-tabs-active")
    expect(liens.first["aria-current"]).to eq("page")
    expect(liens.last["aria-current"]).to be_nil
  end
end
