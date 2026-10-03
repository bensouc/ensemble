# frozen_string_literal: true

require "rails_helper"

# Le formulaire d'une compétence rendait `f.association :domain` dans un bloc
# masqué : simple_form y mettait `Domain.all`, les domaines de toutes les
# écoles, dans le HTML de chaque formulaire de la page des progressions.
RSpec.describe "Formulaire d'une compétence", type: :request do
  let(:enseignant) { create(:user, admin: false) }
  let(:niveau) { create(:grade, school: enseignant.school, name: "CE1", grade_level: "CE1") }
  let!(:domaine) { create(:domain, grade: niveau, name: "Numération", position: 1) }

  before do
    create(:classroom, user: enseignant, grade: niveau)
    create(:skill, school: enseignant.school, domain: domaine, level: 1, name: "Compter jusqu'à 100")
    create(:domain, name: "Domaine secret de Lyon")
    sign_in enseignant
  end

  it "ne contient pas les domaines des autres écoles" do
    get skills_path(grade: niveau.id, domain: domaine.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Domaine secret de Lyon")
  end

  it "garde le domaine de la compétence dans un champ caché" do
    get skills_path(grade: niveau.id, domain: domaine.id)

    page = Nokogiri::HTML(response.body)
    expect(page.css('select[name="skill[domain_id]"]')).to be_empty
    expect(page.css('input[type="hidden"][name="skill[domain_id]"]').map { |champ| champ["value"] }).
      to include(domaine.id.to_s)
  end
end
