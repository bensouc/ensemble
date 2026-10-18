# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Figures de l'énoncé", type: :request do
  let(:enseignant) { create(:user, admin: false) }

  it "est réservé aux comptes connectés" do
    post figures_path, params: { kind: "seyes" }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  describe "insertion depuis l'éditeur" do
    before { sign_in enseignant }

    it "renvoie la pièce jointe d'une horloge" do
      post figures_path, params: { kind: "horloge", heure: "9:45", chiffres: "false" }, as: :json

      corps = response.parsed_body
      expect(corps.keys).to contain_exactly("sgid", "contentType", "content")
      expect(ActionText::Attachable.from_attachable_sgid(corps["sgid"]).id).to eq("horloge-0945-nue")
      expect(corps["contentType"]).to eq(Figure::CONTENT_TYPE)
      expect(corps["content"]).to include("rt-figure-img--horloge")
    end

    # L'éditeur envoie de vrais booléens JSON, pas des chaînes : comparer à
    # "true" ignorait la marge et la case « Chiffres ».
    it "lit les booléens envoyés par l'éditeur" do
      post figures_path, params: { kind: "seyes", marge: true }, as: :json
      expect(ActionText::Attachable.from_attachable_sgid(response.parsed_body["sgid"]).id).to eq("seyes-marge")

      post figures_path, params: { kind: "horloge", heure: "3:15", chiffres: false }, as: :json
      expect(ActionText::Attachable.from_attachable_sgid(response.parsed_body["sgid"]).id).to eq("horloge-0315-nue")
    end

    it "insère du matériel dans la ligne, à la taille de son dessin" do
      post figures_path, params: { kind: "billet", nom: "50" }, as: :json

      corps = response.parsed_body
      expect(ActionText::Attachable.from_attachable_sgid(corps["sgid"]).id).to eq("billet-50")
      expect(corps["contentType"]).to eq(Figure::INLINE_CONTENT_TYPE)
      expect(corps["content"]).to include("rt-figure-img--billet").and include("height: 1.7em")
    end

    it "refuse un billet qui n'existe pas" do
      post figures_path, params: { kind: "billet", nom: "7" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "marque un pictogramme comme se plaçant dans la phrase" do
      post figures_path, params: { kind: "picto", nom: "croix" }, as: :json

      expect(response.parsed_body["contentType"]).to eq(Figure::INLINE_CONTENT_TYPE)
    end

    it "refuse une heure qu'il ne comprend pas" do
      post figures_path, params: { kind: "horloge", heure: "midi passé" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  # rails_admin rend le contenu des exercices hors des helpers de l'application,
  # comme pour les tableaux (#495).
  it "s'affiche dans la liste des exercices de rails_admin" do
    admin = create(:user, admin: true)
    figure = Figure.find("horloge-0315-chiffres")
    create(:challenge, user: admin,
                       content: %(<div>Consigne</div><action-text-attachment sgid="#{figure.attachable_sgid}"></action-text-attachment>))
    sign_in admin

    get "/admin/challenge"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("rt-figure--horloge")
  end
end
