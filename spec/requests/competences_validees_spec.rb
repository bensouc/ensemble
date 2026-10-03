# frozen_string_literal: true

require "rails_helper"

# La modale « compétences acquises » d'un élève : valider sans rien cocher
# n'envoie que le champ vide de simple_form. La page tombait en 500.
RSpec.describe "Validation de compétences sans case cochée", type: :request do
  let(:enseignant) { create(:user, admin: false) }
  let(:eleve) { create(:student, classroom: create(:classroom, user: enseignant)) }

  before { sign_in enseignant }

  def valider_sans_rien(headers = {})
    post student_add_validated_wps_path(eleve), params: { new_wps: { skills: [""] } }, headers:
  end

  it "le dit dans le bandeau, sans rien écrire" do
    expect { valider_sans_rien("Accept" => "text/vnd.turbo-stream.html") }.not_to change(Result, :count)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Cochez au moins une compétence à valider.")
  end

  it "revient sur la fiche de l'élève hors Turbo" do
    valider_sans_rien

    expect(response).to redirect_to(student_path(eleve))
    expect(flash[:alert]).to eq("Cochez au moins une compétence à valider.")
  end
end
