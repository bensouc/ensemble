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

    it "dit à quoi sert l'écran, avec le prénom de l'élève" do
      sign_in teacher

      get mobile_classroom_student_path(classroom, student)

      expect(response.body).to include("Les ceintures obtenues par Leo")
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
    it "liste les élèves de la classe" do
      sign_in teacher

      get mobile_classroom_students_path(classroom)

      expect(response).to be_successful
      expect(response.body).to include("Leo")
    end

    # La route est imbriquée : on veut les élèves de CETTE classe, pas tous ceux
    # que l'enseignant peut voir.
    it "ne montre pas les élèves d'une autre de ses classes" do
      autre = create(:classroom, user: teacher, grade:)
      create(:student, classroom: autre, first_name: "ailleurs")
      sign_in teacher

      get mobile_classroom_students_path(classroom)

      expect(response.body).to include("Leo")
      expect(response.body).not_to include("Ailleurs")
    end

    it "refuse la classe d'une autre école" do
      etrangere = create(:classroom, grade: create(:grade, school: create(:school)))
      sign_in teacher

      get mobile_classroom_students_path(etrangere)

      expect(response).to redirect_to(dashboard_path)
    end
  end
end
