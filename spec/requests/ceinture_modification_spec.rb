# frozen_string_literal: true

require "rails_helper"

# Changer la date d'une ceinture : quand la ceinture elle-même ne passe plus
# ses validations — un doublon élève/domaine/niveau, reste de données
# anciennes —, la branche d'échec faisait `redirect_to :edit`, que Rails
# traduit en `edit_url`, une méthode qui n'existe pas. L'enseignant tombait sur
# une erreur 500.
RSpec.describe "Modification d'une ceinture", type: :request do
  let(:enseignant) { create(:user, admin: false) }
  let(:eleve) { create(:student, classroom: create(:classroom, user: enseignant)) }
  let(:domaine) { create(:domain, name: "Numération") }

  before { sign_in enseignant }

  it "réaffiche le formulaire avec la raison quand la ceinture ne s'enregistre pas" do
    create(:belt, student: eleve, domain: domaine, level: 1, completed: true, validated_date: Date.new(2026, 9, 1))
    doublon = create(:belt, student: eleve, domain: domaine, level: 2, completed: true,
                            validated_date: Date.new(2026, 9, 2))
    doublon.update_column(:level, 1)

    patch belt_path(doublon), params: { belt: { validated_date: "14/09/2026" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("est déjà pris(e)")
  end

  it "enregistre la nouvelle date" do
    ceinture = create(:belt, student: eleve, domain: domaine, level: 1, completed: true,
                             validated_date: Date.new(2026, 9, 1))

    patch belt_path(ceinture), params: { belt: { validated_date: "14/09/2026" } },
                               headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(ceinture.reload.validated_date.to_date).to eq(Date.new(2026, 9, 14))
  end
end
