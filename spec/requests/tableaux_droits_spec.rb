# frozen_string_literal: true

require "rails_helper"

# Un tableau n'a pas de propriétaire : il vit dans l'énoncé d'un exercice.
# L'ancien éditeur le réécrivait par son sgid signé, qui devait donc ne se lire
# que là où se lit l'exercice (`GET /tables/:id` l'avait livré à quiconque
# donnait un id). Avec TipTap, le tableau fait partie du texte de l'énoncé :
# plus de route, plus de sgid exposé.
RSpec.describe "Droits sur les tableaux", type: :request do
  let(:tableau) { Table.create!(rows: 2, columns: 2) }

  before { sign_in create(:user, admin: false) }

  # L'ancien éditeur de tableau écrivait par `POST /tables` et `PATCH
  # /tables/:sgid`. L'éditeur TipTap n'en a plus besoin : plus aucune route
  # n'écrit, ni ne lit, un tableau.
  it "n'expose plus aucune route de tableau" do
    expect { get "/tables/#{tableau.id}" }.to raise_error(ActionController::RoutingError)
    expect { post "/tables", as: :json }.to raise_error(ActionController::RoutingError)
    expect { patch "/tables/#{CGI.escape(tableau.attachable_sgid)}", as: :json }
      .to raise_error(ActionController::RoutingError)
  end

  # Un tableau vit dans l'énoncé d'un exercice, que tous les enseignants de
  # l'école partagent. Avec Trix, la page d'édition livrait son sgid, donc le
  # droit de le réécrire. L'éditeur TipTap reçoit le tableau déjà converti en
  # tableau natif : le sgid ne sort plus, le collègue modifie le tableau dans
  # l'énoncé lui-même.
  it "ne livre plus le sgid du tableau à la page d'édition : il y arrive converti" do
    ecole = create(:school)
    niveau = create(:grade, school: ecole, name: "CE1", grade_level: "CE1")
    competence = create(:skill, school: ecole, level: 1, domain: create(:domain, grade: niveau, name: "Orthographe"))
    tableau.update!(data: { "0-0" => "Loup" })
    piece_jointe = %(<action-text-attachment sgid="#{tableau.attachable_sgid}"></action-text-attachment>)
    exercice = create(:challenge, skill: competence, user: create(:user, school: ecole, admin: false),
                                  content: "<div>Consigne</div>#{piece_jointe}")
    sign_in create(:user, school: ecole, admin: false)

    get edit_challenge_path(exercice)

    expect(response.body).not_to include(tableau.attachable_sgid)
    expect(response.body).to include("&lt;div&gt;Loup&lt;/div&gt;")
  end
end
