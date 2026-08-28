# frozen_string_literal: true

require "rails_helper"

# Le front mobile est une section à part — namespace `mobile`, layout `mobile`,
# atteinte par des liens explicites et non par une détection de user-agent.
# Ces specs fixent ses routes avant qu'on le refonde : sans elles, rien ne
# dirait qu'une refonte a cassé la consultation d'une classe.
RSpec.describe "Mobile::Classrooms", type: :request do
  let(:school) { create(:school) }
  let(:grade) { create(:grade, school:) }
  let(:teacher) { create(:user, admin: false, demo: false) }
  let!(:classroom) { create(:classroom, user: teacher, grade:, name: "CM1 A") }

  before do
    school.add_teacher(teacher)
    teacher.reload
  end

  describe "GET /mobile/classrooms" do
    it "renvoie un visiteur non connecté vers la connexion" do
      get mobile_classrooms_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "liste ses classes" do
      sign_in teacher

      get mobile_classrooms_path

      expect(response).to be_successful
      expect(response.body).to include("CM1 A")
    end

    it "se rend dans le layout mobile, pas celui du bureau" do
      sign_in teacher

      get mobile_classrooms_path

      expect(response).to render_template(layout: "layouts/mobile")
    end

    # Les écrans du mobile s'ouvraient sur une liste sans un mot : rien ne disait
    # ce qu'on pouvait y faire.
    it "dit à quoi sert l'écran" do
      sign_in teacher

      get mobile_classrooms_path

      expect(response.body).to include("consulter les ceintures de vos élèves")
    end

    # La carte situe la classe : son niveau et son effectif, pas seulement un nom.
    it "situe chaque classe par son niveau et son effectif" do
      create(:student, classroom:)
      sign_in teacher

      get mobile_classrooms_path

      expect(response.body).to include(grade.grade_level.upcase)
      expect(response.body).to include("1 élève")
    end

    it "accorde l'effectif au pluriel" do
      create_list(:student, 2, classroom:)
      sign_in teacher

      get mobile_classrooms_path

      expect(response.body).to include("2 élèves")
    end

    # Cinq icônes de la même couleur ne disaient pas où l'on se trouvait.
    it "allume l'onglet courant dans la barre du bas" do
      sign_in teacher

      get mobile_classrooms_path

      expect(response.body).to include('class="mobile-user-menu --actif"')
      expect(response.body).to include('aria-current="page"')
    end

    it "ne montre pas la classe d'un autre enseignant" do
      autre = create(:user, admin: false, demo: false)
      create(:classroom, user: autre, grade:, name: "CE2 SECRETE")
      sign_in teacher

      get mobile_classrooms_path

      expect(response.body).not_to include("CE2 SECRETE")
    end
  end

  describe "GET /mobile/classrooms/:id" do
    it "refuse un visiteur non connecté" do
      get mobile_classroom_path(classroom)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "affiche la classe et ses élèves" do
      student = create(:student, classroom:, first_name: "leo")
      sign_in teacher

      get mobile_classroom_path(classroom)

      expect(response).to be_successful
      expect(response.body).to include("Leo")
    end

    # Une classe partagée reste consultable par le collègue : `ClassroomPolicy#show?`
    # accepte le propriétaire ET les profs du partage.
    it "reste accessible au collègue avec qui elle est partagée" do
      collegue = create(:user, admin: false, demo: false)
      school.add_teacher(collegue)
      create(:shared_classroom, user: collegue, classroom:)
      sign_in collegue

      get mobile_classroom_path(classroom)

      expect(response).to be_successful
    end

    it "refuse la classe d'une autre école" do
      ailleurs = create(:classroom, grade: create(:grade, school: create(:school)))
      sign_in teacher

      get mobile_classroom_path(ailleurs)

      expect(response).to redirect_to(dashboard_path)
    end
  end
end
