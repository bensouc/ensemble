# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Manipule, le domaine « Autre »" do
  # La factory :user fabrique un ADMIN, qui voit tout : les tests de
  # cloisonnement ne testeraient alors rien.
  let(:enseignante) { create(:user, admin: false, manipule: true) }
  let(:niveau) { create(:grade, school: enseignante.school, name: "CE1", grade_level: "CE1") }
  let!(:sa_classe) { create(:classroom, user: enseignante, grade: niveau) }

  before { sign_in enseignante }

  it "n'affiche que les niveaux de ses classes" do
    create(:grade, school: enseignante.school, name: "CM2", grade_level: "CM2")

    get manipule_autre_path

    expect(assigns(:niveaux)).to eq([niveau])
  end

  it "crée la compétence, et le domaine avec elle" do
    post manipule_autre_path, params: { grade_id: niveau.id, nom: "Le nombre du jour", ceinture: 2 }

    competence = Skill.find_by(name: "Le nombre du jour")
    expect(competence.level).to eq(2)
    expect(competence.domain.name).to eq("Autre")
    expect(competence.domain.manipule).to be(true)
    expect(competence.school).to eq(enseignante.school)
  end

  it "ne crée qu'un domaine « Autre » par niveau" do
    2.times { |rang| post manipule_autre_path, params: { grade_id: niveau.id, nom: "Compétence #{rang}", ceinture: 1 } }

    expect(Domain.where(grade: niveau, manipule: true).count).to eq(1)
  end

  # Un nom vide ne doit pas lever une 500 devant l'enseignante.
  it "redit l'erreur plutôt que de casser quand le nom manque" do
    post manipule_autre_path, params: { grade_id: niveau.id, nom: "", ceinture: 1 }

    expect(response).to redirect_to(manipule_autre_path)
    expect(flash[:alert]).to be_present
    expect(Skill.where(name: "")).to be_empty
  end

  describe "le cloisonnement" do
    it "ne range rien dans le niveau d'un autre enseignant" do
      ailleurs = create(:classroom, user: create(:user, admin: false)).grade

      post manipule_autre_path, params: { grade_id: ailleurs.id, nom: "Intrusion", ceinture: 1 }

      expect(response).to have_http_status(:redirect)
      expect(Skill.where(name: "Intrusion")).to be_empty
    end

    it "l'option fermée ferme la page" do
      sign_in create(:user, admin: false, manipule: false)

      get manipule_autre_path

      expect(response).to redirect_to(root_path)
    end
  end
end
