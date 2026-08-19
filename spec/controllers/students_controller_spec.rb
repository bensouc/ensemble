# frozen_string_literal: true

require "rails_helper"

RSpec.describe StudentsController, type: :controller do
  let(:user) { create(:user) }
  let(:grade) { create(:grade, school: user.school) }
  let(:classroom) { create(:classroom, grade: grade) }
  let(:student) { create(:student, classroom: classroom) }
  let(:domain1) { create(:domain, grade: grade) }
  let(:skill1) { create(:skill, domain: domain1, level: 1) }
  let(:skill2) { create(:skill, domain: domain1, level: 2) }

  before { sign_in user }

  describe "GET #show" do
    context "when format is HTML" do
      it "render the html student show" do
        get :show, params: { id: student.id }, format: :html
        # expect url to be equivalent to the student path
        expect(response).to be_successful
      end
    end

    context "when format is PDF" do
      it "generates a PDF and sends it as an attachment" do
        get :show, params: { id: student.id }, format: :pdf
        expect(response.headers["Content-Type"]).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("attachment")
      end
    end
  end

  describe "PATCH #transfer" do
    let(:destination) { create(:classroom, grade: grade) }
    let(:other_grade) { create(:grade, school: user.school, name: "NivAutre", grade_level: "CM1") }
    let(:other_level) { create(:classroom, grade: other_grade) }

    it "déplace l'élève vers une classe du même niveau" do
      patch :transfer, params: { id: student.id, student: { classroom_id: destination.id } }
      expect(student.reload.classroom).to eq(destination)
      expect(flash[:notice]).to be_present
    end

    it "refuse une classe d'un autre niveau sans déplacer l'élève" do
      patch :transfer, params: { id: student.id, student: { classroom_id: other_level.id } }
      expect(student.reload.classroom).to eq(classroom)
      expect(flash[:alert]).to be_present
    end

    it "refuse un identifiant de classe inexistant" do
      patch :transfer, params: { id: student.id, student: { classroom_id: 0 } }
      expect(student.reload.classroom).to eq(classroom)
      expect(flash[:alert]).to be_present
    end
  end
end
