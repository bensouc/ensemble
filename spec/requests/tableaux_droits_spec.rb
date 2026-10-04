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

  # Le sgid d'une image collée dans l'énoncé est signé pour le même usage
  # (« attachable ») : l'éditeur ne doit accepter que celui d'un tableau.
  it "répond 404 au sgid d'une image" do
    image = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("png"), filename: "photo.png",
                                                   content_type: "image/png")

    patch "/tables/#{CGI.escape(image.attachable_sgid)}",
          params: { method: "replace", table: { rows: 2, columns: 2 } }, as: :json

    expect(response).to have_http_status(:not_found)
  end

  # Un tableau vit dans l'énoncé d'un exercice, que tous les enseignants de
  # l'école partagent : un collègue lit le sgid dans l'exercice d'un autre, et
  # modifie le tableau avec.
  it "laisse un collègue de l'école modifier le tableau de l'exercice d'un autre" do
    ecole = create(:school)
    niveau = create(:grade, school: ecole, name: "CE1", grade_level: "CE1")
    competence = create(:skill, school: ecole, level: 1, domain: create(:domain, grade: niveau, name: "Orthographe"))
    piece_jointe = %(<action-text-attachment sgid="#{tableau.attachable_sgid}"></action-text-attachment>)
    exercice = create(:challenge, skill: competence, user: create(:user, school: ecole, admin: false),
                                  content: "<div>Consigne</div>#{piece_jointe}")
    sign_in create(:user, school: ecole, admin: false)

    get edit_challenge_path(exercice)
    expect(response.body).to include(tableau.attachable_sgid)

    patch "/tables/#{CGI.escape(tableau.attachable_sgid)}",
          params: { method: "replace", table: { rows: 2, columns: 2, data: { "0-0" => "Loup" } } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(tableau.reload.cell(0, 0)).to eq("Loup")
  end
end
