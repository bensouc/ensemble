# frozen_string_literal: true

require "rails_helper"

# Un niveau tout neuf n'a encore aucun domaine : c'est le cas d'une école qui
# démarre, ou d'un niveau ajouté en cours d'année. Les exercices et les
# compétences doivent le dire, et mener à la création des domaines, au lieu de
# planter.
RSpec.describe "Un niveau sans domaine", type: :request do
  let(:school) { create(:school) }
  let(:enseignant) { create(:user, school:, admin: false) }
  let(:grade) { create(:grade, school:, name: "CM1", grade_level: "CM1") }

  before do
    create(:classroom, user: enseignant, grade:)
    sign_in enseignant
  end

  it "ouvre les exercices, et dit qu'il faut d'abord des domaines" do
    get challenges_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Aucun domaine pour ce niveau", skills_path(grade: grade.id))
  end

  it "ouvre les compétences sur la gestion des domaines, pour en créer" do
    get skills_path(grade: grade.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Gérer vos domaines pour le niveau CM1", "Ajouter un domaine")
  end
end
