# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::ButtonComponent, type: :component do
  it "rend un <button> de type button, en variante secondaire et taille moyenne par défaut" do
    bouton = render_inline(described_class.new("Ajouter")).at_css("button")

    expect(bouton["type"]).to eq("button")
    expect(bouton["class"]).to eq("ui-btn ui-btn--secondary")
    expect(bouton.text.strip).to eq("Ajouter")
  end

  it "porte la variante et la petite taille dans ses classes" do
    bouton = render_inline(described_class.new("Valider", variant: :primary, size: :sm, type: "submit")).at_css("button")

    expect(bouton["type"]).to eq("submit")
    expect(bouton["class"]).to eq("ui-btn ui-btn--primary ui-btn--sm")
  end

  it "a une grande taille, celle de la cible tactile, pour les icônes à côté d'un titre" do
    bouton = render_inline(described_class.new(variant: :icon, size: :lg, icon: "fa-bacon", title: "Fiche")).
      at_css("button")

    expect(bouton["class"]).to eq("ui-btn ui-btn--icon ui-btn--lg")
  end

  it "passe ses attributs data, et garde une classe en plus" do
    bouton = render_inline(described_class.new("Annuler", variant: :neutral,
                                                          data: { bs_dismiss: "modal" },
                                                          html: { class: "ms-2", id: "annuler" })).at_css("button")

    expect(bouton["data-bs-dismiss"]).to eq("modal")
    expect(bouton["class"]).to eq("ui-btn ui-btn--neutral ms-2")
    expect(bouton["id"]).to eq("annuler")
  end

  it "devient un lien avec `href:`" do
    lien = render_inline(described_class.new("Progression", href: "/students/1", icon: "fa-arrow-left")).at_css("a")

    expect(lien["href"]).to eq("/students/1")
    expect(lien.at_css("i.fa-solid.fa-arrow-left")).to be_present
  end

  it "devient un formulaire d'un bouton avec `url:`, et garde la famille d'icône donnée" do
    page = render_inline(described_class.new("Cloner", url: "/challenges/1/duplicate", icon: "fa-regular fa-clone",
                                                       form: { data: { turbo_confirm: "Sûr ?" } }))

    expect(page.at_css("form[action='/challenges/1/duplicate'][data-turbo-confirm='Sûr ?']")).to be_present
    expect(page.at_css("form button.ui-btn--secondary i.fa-regular.fa-clone")).to be_present
  end

  it "donne à une icône seule son title comme nom accessible" do
    bouton = render_inline(described_class.new(variant: :icon, icon: "fa-ellipsis-vertical", title: "Actions")).
      at_css("button")

    expect(bouton["aria-label"]).to eq("Actions")
    expect(bouton.at_css("span")).to be_nil
  end

  it "accepte un libellé en bloc" do
    bouton = render_inline(described_class.new(variant: :success)) { "Enregistrer" }.at_css("button")

    expect(bouton.text.strip).to eq("Enregistrer")
  end

  it "refuse une variante qui n'existe pas" do
    expect { described_class.new("X", variant: :danger) }.to raise_error(ArgumentError, /variante inconnue/)
  end
end
