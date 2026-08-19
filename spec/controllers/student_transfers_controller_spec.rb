# frozen_string_literal: true

require "rails_helper"

RSpec.describe StudentTransfersController, type: :controller do
  render_views

  let(:user) { create(:user) }
  let(:grade) { create(:grade, school: user.school, name: "NivOrigine", grade_level: "CE1") }
  let(:classroom) { create(:classroom, grade: grade) }
  let(:student) { create(:student, classroom: classroom) }
  let(:destination) { create(:classroom, grade: grade) }
  let(:other_grade) { create(:grade, school: user.school, name: "NivAutre", grade_level: "CM1") }
  let(:other_level) { create(:classroom, grade: other_grade) }

  before { sign_in user }

  describe "GET #new" do
    it "sert le formulaire de transfert avec les classes du même niveau" do
      destination
      get :new, params: { student_id: student.id }
      expect(response).to be_successful
      expect(response.body).to include("Transférer")
    end
  end

  describe "POST #create" do
    it "déplace l'élève vers une classe du même niveau" do
      post :create, params: { student_id: student.id, student: { classroom_id: destination.id } }
      expect(student.reload.classroom).to eq(destination)
      expect(flash[:notice]).to be_present
    end

    it "refuse une classe d'un autre niveau sans déplacer l'élève" do
      post :create, params: { student_id: student.id, student: { classroom_id: other_level.id } }
      expect(student.reload.classroom).to eq(classroom)
      expect(flash[:alert]).to be_present
    end

    it "refuse un identifiant de classe inexistant" do
      post :create, params: { student_id: student.id, student: { classroom_id: 0 } }
      expect(student.reload.classroom).to eq(classroom)
      expect(flash[:alert]).to be_present
    end
  end
end
