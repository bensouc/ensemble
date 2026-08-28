# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile::Students", type: :request do
  let(:school) { create(:school) }
  let(:grade) { create(:grade, school:) }
  let(:teacher) { create(:user, admin: false, demo: false) }
  let(:classroom) { create(:classroom, user: teacher, grade:) }
  let!(:student) { create(:student, classroom:, first_name: "leo") }

  before do
    school.add_teacher(teacher)
    teacher.reload
  end

  describe "GET /mobile/classrooms/:classroom_id/students/:id" do
    it "refuse un visiteur non connecté" do
      get mobile_classroom_student_path(classroom, student)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "affiche l'élève et ses ceintures par domaine" do
      sign_in teacher

      get mobile_classroom_student_path(classroom, student)

      expect(response).to be_successful
      expect(response.body).to include("Leo")
    end

    it "refuse l'élève d'une autre école" do
      ailleurs = create(:student, classroom: create(:classroom, grade: create(:grade, school: create(:school))))
      sign_in teacher

      get mobile_classroom_student_path(classroom, ailleurs)

      expect(response).to redirect_to(dashboard_path)
    end

    it "refuse l'élève de la classe d'un collègue, même dans son école" do
      collegue = create(:user, admin: false, demo: false)
      school.add_teacher(collegue)
      voisin = create(:student, classroom: create(:classroom, user: collegue, grade:))
      sign_in teacher

      get mobile_classroom_student_path(classroom, voisin)

      expect(response).to redirect_to(dashboard_path)
    end

    it "accepte l'élève d'une classe partagée avec soi" do
      collegue = create(:user, admin: false, demo: false)
      school.add_teacher(collegue)
      partagee = create(:classroom, user: collegue, grade:)
      create(:shared_classroom, user: teacher, classroom: partagee)
      confie = create(:student, classroom: partagee, first_name: "mia")
      sign_in teacher

      get mobile_classroom_student_path(partagee, confie)

      expect(response).to be_successful
      expect(response.body).to include("Mia")
    end
  end

  describe "GET /mobile/classrooms/:classroom_id/students" do
    # `Mobile::StudentsController#index` appelle `policy_scope(Student)`, mais
    # `StudentPolicy::Scope` est commentée dans la policy. Pundit se rabat donc
    # sur `ApplicationPolicy::Scope`, dont `resolve` lève NotImplementedError :
    # l'action renvoie une 500 depuis toujours. Elle ne pose de surcroît pas
    # `@classroom`, que son gabarit attend.
    it "devrait lister les élèves de la classe" do
      pending "StudentPolicy::Scope commentée -> ApplicationPolicy::Scope#resolve lève NotImplementedError"
      sign_in teacher

      get mobile_classroom_students_path(classroom)

      expect(response).to be_successful
      expect(response.body).to include("Leo")
    end
  end
end
