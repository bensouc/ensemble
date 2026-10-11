# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::PageComponent, type: :component do
  it "pose le titre, les onglets de la section, puis le contenu" do
    page = render_inline(described_class.new(title: "Ceintures", tabs: [
                                               { label: "Ceintures", href: "/belt_sheets", active: true },
                                               { label: "Exercices", href: "/challenges?ceinture=1" }
                                             ])) { "<p>la liste</p>".html_safe }

    expect(page.at_css(".ui-page-header h1.ui-page-title").text).to eq("Ceintures")
    expect(page.css(".ui-tabs a").map(&:text)).to eq(%w[Ceintures Exercices])
    expect(page.at_css(".ui-page > p").text).to eq("la liste")
  end

  it "n'affiche pas de barre d'onglets vide, et accepte une action à droite du titre" do
    component = described_class.new(title: "Seul")
    page = render_inline(component) do |c|
      c.with_actions { "<button>PDF</button>".html_safe }
      "contenu"
    end

    expect(page.at_css(".ui-tabs")).to be_nil
    expect(page.at_css(".ui-page-actions button").text).to eq("PDF")
  end
end
