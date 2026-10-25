# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::AvatarComponent, type: :component do
  let(:prof) { build_stubbed(:user, first_name: "élodie", last_name: "Durand", admin: false) }

  def rond(user, **options)
    render_inline(described_class.new(user, **options)).at_css(".ui-avatar")
  end

  it "montre les initiales, accents gardés, quand il n'y a pas de photo" do
    avatar = rond(prof)

    expect(avatar.name).to eq("span")
    expect(avatar.text).to eq("ÉD")
    expect(avatar["role"]).to eq("img")
    expect(avatar["aria-label"]).to eq("Élodie Durand")
    expect(avatar["class"]).to include("ui-avatar--md")
  end

  it "prend la première lettre de l'email d'un invité sans nom" do
    invite = build_stubbed(:user, first_name: nil, last_name: " ", email: "invite@exemple.fr")

    expect(rond(invite).text).to eq("I")
  end

  it "garde la même teinte pour un compte, et en change d'un compte au suivant" do
    teintes = [3, 4, 6].map { |id| rond(build_stubbed(:user, id:))["class"][/ui-avatar--teinte-\d/] }

    expect(teintes).to eq(%w[ui-avatar--teinte-0 ui-avatar--teinte-1 ui-avatar--teinte-0])
  end

  it "montre la photo, recadrée sur le visage au double de la taille affichée" do
    allow(prof).to receive(:avatar).and_return(double(attached?: true, key: "cle-de-la-photo"))

    avatar = rond(prof, size: :sm)

    expect(avatar.name).to eq("img")
    expect(avatar["alt"]).to eq("Élodie Durand")
    expect(avatar["src"]).to include("c_fill", "g_face", "h_50", "w_50", "cle-de-la-photo")
  end

  it "ne montre le logo d'Ensemble pour un admin que si on le demande" do
    admin = build_stubbed(:user, first_name: "Benoît", last_name: "Moret", admin: true)

    expect(rond(admin).text).to eq("BM")
    expect(rond(admin, logo_pour_admin: true)["src"]).to include("vroad_b_w")
    expect(rond(prof, logo_pour_admin: true).text).to eq("ÉD")
  end

  it "passe ses attributs, et garde une classe en plus" do
    avatar = rond(prof, size: :sm, html: { class: "me-1", title: "Élodie", data: { message_target: "avatar" } })

    expect(avatar["class"]).to eq("ui-avatar ui-avatar--sm ui-avatar--teinte-#{prof.id % 3} me-1")
    expect(avatar["title"]).to eq("Élodie")
    expect(avatar["data-message-target"]).to eq("avatar")
  end

  it "refuse une taille inconnue" do
    expect { described_class.new(prof, size: :xxl) }.to raise_error(ArgumentError)
  end
end
