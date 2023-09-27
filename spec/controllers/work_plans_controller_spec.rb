# frozen_string_literal: true

require "rails_helper"
RSpec.describe WorkPlansController, type: :controller do
  let(:user) { create(:user) }
  let(:work_plan) { create(:work_plan, user:) }
  let(:classroom) { create(:classroom, user:) }
  let(:valid_params) { { work_plan_id: work_plan.id } }

  describe "#index" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :index
        expect(response).not_to be_successful
      end
    end
    context "when user is not signed in" do
      before { sign_in user }
      it "returns a successful response" do
        get :index
        expect(response).to be_successful
      end
    end
  end

  # describe "#index signed in" do
  # end
  describe "#new" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :new
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "returns a successful response" do
        sign_in(user)
        get :new
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end
    end
  end

  describe "#show" do
    before { sign_in user }
    it "returns a successful response" do
      # work_plan = WorkPlan.last
      get :show, params: { id: work_plan.id }
      expect(response).to be_successful
    end
  end

  describe "#clone" do
    before { sign_in user }
    context "with no student" do
      it "creates a new one and redirect to It" do
        post :clone, params: valid_params
        expect(response).to redirect_to(work_plan_path(WorkPlan.last))
      end
    end

    context "with two students" do
      before { sign_in user }
      let(:student1) { create(:student, classroom:) }
      let(:student2) { create(:student, classroom:) }

      it "creates a two new wp and redirect to index" do
        valid_params = {
          work_plan_id: work_plan.id,
          "/work_plans/#{work_plan.id}" => {
            students: [student1, student2],
          },
        }
        expect do
          post :clone, params: valid_params
        end.to change(WorkPlan, :count).by(2)
        expect(response).to redirect_to(work_plans_path)
      end
    end
  end

  describe "#evaluation" do
    before { sign_in user }
    it "redirect to the workplan evaluation page" do
      get :show, params: { id: work_plan.id }
      expect(response).to be_successful
    end
  end

  describe "#update" do
    before { sign_in user }
    context "with valid params" do
      let(:new_attributes) do
        { name: "new name",
          student_id: work_plan.student,
          start_date: Time.zone.today, end_date: Time.zone.today + 1 }
      end

      it "updates the work_plan name/ start_date /end_date" do
        put :update, params: { id: work_plan.id, work_plan: new_attributes }
        work_plan.reload
        expect(work_plan.name).to eq("new name")
        expect(work_plan.start_date).to eq(Time.zone.today)
        expect(work_plan.end_date).to eq(Time.zone.today + 1)
      end

      it "redirects to the work_plan" do
        put :update, params: { id: work_plan.id, work_plan: new_attributes }
        expect(response).to redirect_to(work_plan)
      end
    end
  end

  describe "#auto_gen" do
    before { sign_in user }
    context "with valid params" do
      let(:student) { create(:student, classroom:) }
      let(:params) do
        {
          "/students/#{student.id}" => {
            domains: ["", "Conjugaison", "Vocabulaire", "Orthographe", "Grandeurs et Mesures"],
          },
        }
      end
      it "generate a new work_plan, based on the student's actual progression" do
        expect do
          post :auto_new_wp, params: params.merge(student_id: student.id)
        end.to change(WorkPlan, :count).by(1)
        # expect(response).to redirect_to(work_plan_path(WorkPlan.last))
      end
      it "redirects to the Auto Generated WorkPlan " do
        post :auto_new_wp, params: params.merge(student_id: student.id)
        expect(response).to redirect_to(work_plan_path(WorkPlan.last))
      end
    end
  end
end
