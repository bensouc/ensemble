# frozen_string_literal: true

require "rails_helper"

# rails_admin liste les exercices avec leur contenu ActionText. ActionText rend
# alors la partial d'un tableau dans le contexte du contrôleur de rails_admin,
# qui n'a pas les helpers de l'application : la liste tombait en 500 dès qu'un
# exercice contenait un tableau.
RSpec.describe "Liste des exercices dans rails_admin", type: :request do
  it "s'affiche quand un exercice contient un tableau" do
    admin = create(:user, admin: true)
    tableau = Table.create!(columns: 2, rows: 2)
    piece_jointe = %(<action-text-attachment sgid="#{tableau.attachable_sgid}"></action-text-attachment>)
    create(:challenge, user: admin, content: "<div>Consigne</div>#{piece_jointe}")
    sign_in admin

    get "/admin/challenge"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("rt-cell")
  end
end
