require "rails_helper"
RSpec.describe WorkPlansController, type: :controller do
  let(:user) { User.last }
  let(:work_plan) { create(:work_plan, user: user) }
  let(:classroom) { create(:classroom, user: user) }
  let(:valid_params) { { work_plan_id: work_plan.id } }

  before { sign_in user }

  describe "#index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "#show" do
    it "returns a successful response" do
      # work_plan = WorkPlan.last
      get :show, params: { id: work_plan.id }
      expect(response).to be_successful
    end
  end

  describe "#clone" do
    context "with no student" do
      it "creates a new one and redirect to It" do
        post :clone, params: valid_params
        expect(response).to redirect_to(work_plan_path(WorkPlan.last))
      end
    end

    context "to two students" do
      it "creates a two new wp and redirect to index" do
        post :clone, params: valid_params
        expect(response).to redirect_to(work_plans_path)
      end
    end
  end

  describe "#evaluation" do
    it "redirect to the workplan evaluation page" do
      get :show, params: { id: work_plan.id }
      expect(response).to be_successful
    end
  end

  describe "#update" do
    context "with valid params" do
      let(:new_attributes) {
        { name: "new name",
          student_id: work_plan.student,
          start_date: Date.today, end_date: Date.today + 1 }
      }

      it "updates the work_plan name/ start_date /end_date" do
        put :update, params: { id: work_plan.id, work_plan: new_attributes }
        work_plan.reload
        expect(work_plan.name).to eq("new name")
        expect(work_plan.start_date).to eq(Date.today)
        expect(work_plan.end_date).to eq(Date.today + 1)
      end

      it "redirects to the work_plan" do
        put :update, params: { id: work_plan.id, work_plan: new_attributes }
        expect(response).to redirect_to(work_plan)
      end
    end
  end

  describe "#auto_gen" do
    context "with valid params" do
      let(:student) { create (:student) }
      let(:params) do {
        "/students/#{student.id}" => {
          domains: ["", "Conjugaison", "Vocabulaire", "Orthographe", "Grandeurs et Mesures"],
        },
      }       end
      it "generate a new work_plan, based on the student's actual progression" do
        expect {
          post :auto_new_wp, params: params.merge(student_id: student.id)
        }.to change(WorkPlan, :count).by(1)
        # expect(response).to redirect_to(work_plan_path(WorkPlan.last))
      end
      it "redirects to the Auto Generated WorkPlan " do
        post :auto_new_wp, params: params.merge(student_id: student.id)
        expect(response).to redirect_to(work_plan_path(WorkPlan.last))
      end
    end
  end
end
