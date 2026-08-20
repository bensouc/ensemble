# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModalsController, type: :controller do
  let(:user) { create(:user) }
  let(:grade) { create(:grade, school: user.school) }
  let(:classroom) { create(:classroom, user:, grade:) }
  let(:student) { create(:student, classroom:) }

  describe "#new_work_plan" do
    render_views

    context "when user is not signed in" do
      it "returns a failure response" do
        get :new_work_plan, params: { id: student.id }
        expect(response).not_to be_successful
      end
    end

    context "when user is signed in" do
      before { sign_in(user) }

      it "propose les deux issues : plan vierge et génération automatique" do
        get :new_work_plan, params: { id: student.id }

        expect(response).to be_successful
        expect(response.body).to include(work_plans_path)
        expect(response.body).to include(student_auto_new_wp_path(student))
        expect(response.body).to include(student.first_name.capitalize)
      end

      it "préremplit un nom, la semaine en cours et l'élève" do
        get :new_work_plan, params: { id: student.id }

        monday = Date.current.at_beginning_of_week
        expect(assigns(:work_plan).student).to eq(student)
        expect(assigns(:work_plan).grade).to eq(grade)
        expect(assigns(:work_plan).start_date).to eq(monday)
        expect(assigns(:work_plan).end_date).to eq(monday + 4)
        expect(response.body).to include(monday.strftime("%d/%m/%Y"))
      end

      it "refuse un élève qui n'est pas dans les classes de l'enseignant" do
        other_student = create(:student, classroom: create(:classroom))

        get :new_work_plan, params: { id: other_student.id }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
