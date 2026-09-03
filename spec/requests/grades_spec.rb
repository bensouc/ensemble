require 'rails_helper'

RSpec.describe "Grades", type: :request do
  let(:school) { create(:school) }
  let(:user) { create(:user, school:, admin: false) }

  let(:turbo_headers) do
    { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
      "Turbo-Frame" => "new_grade" }
  end

  before { sign_in user }

  describe "POST /grades" do
    it "crée le niveau" do
      post grades_path, params: { grade: { name: "CE1", grade_level: "CE1", school_id: school.id } },
                        headers: turbo_headers

      expect(school.grades.pluck(:name)).to eq(["CE1"])
    end

    it "réaffiche le formulaire avec l'erreur quand l'alias est déjà utilisé dans l'école" do
      create(:grade, school:, name: "CE1", grade_level: "CE1")

      post grades_path, params: { grade: { name: "CE1", grade_level: "CE2", school_id: school.id } },
                        headers: turbo_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nom est déjà utilisé dans votre école")
      expect(school.grades.count).to eq(1)
    end

    it "réaffiche le formulaire avec l'erreur quand l'alias est trop long" do
      post grades_path, params: { grade: { name: "a" * 16, grade_level: "CE1", school_id: school.id } },
                        headers: turbo_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nom est trop long (pas plus de 15 caractères)")
    end
  end
end
