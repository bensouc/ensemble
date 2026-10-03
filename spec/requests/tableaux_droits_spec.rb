# frozen_string_literal: true

require "rails_helper"

# Un tableau n'a pas de propriétaire : il vit dans l'énoncé d'un exercice, et
# l'éditeur le modifie par son sgid signé (`PATCH /tables/:sgid`). Ce sgid ne
# doit donc se lire que là où se lit l'exercice. `GET /tables/:id`, que rien
# n'appelait, le livrait pour n'importe quel tableau à qui en donnait l'id —
# un compteur suffisait pour réécrire les tableaux de toutes les écoles.
RSpec.describe "Droits sur les tableaux", type: :request do
  let(:tableau) { Table.create!(rows: 2, columns: 2) }

  before { sign_in create(:user, admin: false) }

  it "ne livre pas le sgid d'un tableau à qui en donne l'id" do
    expect { get "/tables/#{tableau.id}" }.to raise_error(ActionController::RoutingError)
  end

  # Le chemin de l'éditeur reste ouvert : il crée son tableau, puis l'enregistre
  # par le sgid qu'il a reçu.
  it "crée un tableau puis l'enregistre par son sgid" do
    post tables_path, as: :json
    sgid = response.parsed_body["sgid"]

    patch "/tables/#{CGI.escape(sgid)}",
          params: { method: "replace", table: { rows: 2, columns: 2, data: { "0-0" => "Mot" } } }, as: :json

    expect(response).to have_http_status(:ok)
    expect(Table.last.cell(0, 0)).to eq("Mot")
  end
end
