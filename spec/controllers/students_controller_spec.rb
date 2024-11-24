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

end
