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

    # `StudentPolicy#show?` renvoie `true` sans condition : n'importe quel
    # enseignant connecté peut consulter n'importe quel élève, même d'une autre
    # école. La spec décrit le comportement ATTENDU et reste `pending` : le jour
    # où la policy est corrigée, elle passera au vert et signalera qu'il faut la
    # dé-marquer.
    it "devrait refuser l'élève d'une autre école" do
      pending "StudentPolicy#show? renvoie true sans condition"
      ailleurs = create(:student, classroom: create(:classroom, grade: create(:grade, school: create(:school))))
      sign_in teacher

      get mobile_classroom_student_path(classroom, ailleurs)

      expect(response).to redirect_to(dashboard_path)
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
