# frozen_string_literal: true

require "rails_helper"
RSpec.describe SharedClassroomsController, type: :controller do
  let(:user) { create(:user) }
  let(:user2) { create(:user, school: user.school) }
  let(:classroom) { create(:classroom, user:) }
  let(:work_plan) { create(:work_plan, user:) }
  let(:set_classroom) { { classroom_id: classroom.id } }
  let(:set_shared_classroom_teacher_params) { { teachers: ["", user2.id.to_s] } }

  describe "#create" do
    context "when user is not signed in" do
      it "returns a failure response" do
        post :create, params: set_classroom
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      before { sign_in user }
      it " creates a new SharedClassromm" do
        expect do
          post :create,
               params: {
                 classroom_id: classroom.id,
                 classroom.id.to_s => { teachers: ["", user2.id.to_s] },
               }
        end.to change(SharedClassroom, :count).by(1)
        # change(work_plan.work_plan_domains.first.work_plan_skills, :count).by(1)
      end
    end
  end

  describe "#destroy" do
    context "when user is signed in" do
      it "deletes the shared_classroom" do
        sign_in user
        shared_classroom = create(:shared_classroom, user: user2, classroom: )
        expect {
          delete :destroy , params: {
          id: shared_classroom.id,
          classroom_id: classroom.id}
        }.to change(SharedClassroom, :count).by(-1)
      end
    end
  end

  # describe "#index" do
  #   context "when user is not signed in" do
  #     it "returns a failure response" do
  #       get :index
  #       expect(response).not_to be_successful
  #     end
  #   end
  #   context "when user is not signed in" do
  #     before { sign_in user }
  #     it "returns a successful response" do
  #       get :index
  #       expect(response).to be_successful
  #     end
  #   end
  # end

  # # describe "#index signed in" do
  # # end

  # describe "#show" do
  #   before { sign_in user }
  #   it "returns a successful response" do
  #     # work_plan = WorkPlan.last
  #     get :show, params: { id: work_plan.id }
  #     expect(response).to be_successful
  #   end
  # end

  # describe "#clone" do
  #   before { sign_in user }
  #   context "with no student" do
  #     it "creates a new one and redirect to It" do
  #       post :clone, params: valid_params
  #       expect(response).to redirect_to(work_plan_path(WorkPlan.last))
  #     end
  #   end

  #   context "with two students" do
  #     before { sign_in user }
  #     let(:student1) { create(:student, classroom:) }
  #     let(:student2) { create(:student, classroom:) }

  #     it "creates a two new wp and redirect to index" do
  #       valid_params = {
  #         work_plan_id: work_plan.id,
  #         "/work_plans/#{work_plan.id}" => {
  #           students: [student1, student2],
  #         },
  #       }
  #       expect do
  #         post :clone, params: valid_params
  #       end.to change(WorkPlan, :count).by(2)
  #       expect(response).to redirect_to(work_plans_path)
  #     end
  #   end
  # end

  # describe "#evaluation" do
  #   before { sign_in user }
  #   it "redirect to the workplan evaluation page" do
  #     get :show, params: { id: work_plan.id }
  #     expect(response).to be_successful
  #   end
  # end

  # describe "#update" do
  #   before { sign_in user }
  #   context "with valid params" do
  #     let(:new_attributes) do
  #       { name: "new name",
  #         student_id: work_plan.student,
  #         start_date: Time.zone.today, end_date: Time.zone.today + 1 }
  #     end

  #     it "updates the work_plan name/ start_date /end_date" do
  #       put :update, params: { id: work_plan.id, work_plan: new_attributes }
  #       work_plan.reload
  #       expect(work_plan.name).to eq("new name")
  #       expect(work_plan.start_date).to eq(Time.zone.today)
  #       expect(work_plan.end_date).to eq(Time.zone.today + 1)
  #     end

  #     it "redirects to the work_plan" do
  #       put :update, params: { id: work_plan.id, work_plan: new_attributes }
  #       expect(response).to redirect_to(work_plan)
  #     end
  #   end
  # end

  # describe "#auto_gen" do
  #   before { sign_in user }
  #   context "with valid params" do
  #     let(:student) { create(:student, classroom:) }
  #     let(:params) do
  #       {
  #         "/students/#{student.id}" => {
  #           domains: ["", "Conjugaison", "Vocabulaire", "Orthographe", "Grandeurs et Mesures"],
  #         },
  #       }
  #     end
  #     it "generate a new work_plan, based on the student's actual progression" do
  #       expect do
  #         post :auto_new_wp, params: params.merge(student_id: student.id)
  #       end.to change(WorkPlan, :count).by(1)
  #       # expect(response).to redirect_to(work_plan_path(WorkPlan.last))
  #     end
  #     it "redirects to the Auto Generated WorkPlan " do
  #       post :auto_new_wp, params: params.merge(student_id: student.id)
  #       expect(response).to redirect_to(work_plan_path(WorkPlan.last))
  #     end
  #   end
  # end
end
