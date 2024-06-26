# frozen_string_literal: true

require "rails_helper"
RSpec.describe BeltsController, type: :controller do
  let(:user) { create(:user) }
  let(:classroom) { create(:classroom, user:) }
  let(:student) { create(:student, classroom:) }
  let(:work_plan) { create(:work_plan, user:, student:) }
  let(:grade) {create(:grade)}
  let(:domain) {create(:domain,grade:)}

  before { sign_in user }

  describe "create" do
    # params.require(:belt).permit(:grade, :domain, :level, :grade, :validated_date)
    let(:valid_params) { { belt: {  domain_id: domain.id , level: (1..7).to_a.sample, validated_date: Faker::Date }, student_id: student.id } }
    it "creates a new Belt with the right params" do
      # p grade
      expect do
        post :create, params: valid_params
      end.to change(Belt, :count).by(1)
    end
    let(:unvalid_params) { { belt: { grade_id: grade,domain_id: domain.id, level: "0", validated_date: Faker::Date }, student_id: student.id } }
    it "failed to creates a new Belt with the right params" do
      expect do
        post :create, params: unvalid_params
      end.to change(Belt, :count).by(0)
    end
  end

  describe "update" do
    let(:belt) { create(:belt, student:, domain: domain, level: "1") }
    let(:valid_params) { { belt: { validated_date: (DateTime.now + 2) }, id: belt.id } }
    it "updates a Belt with the right new date" do
      original_date = belt.validated_date
      patch :update, params: valid_params
      expect(belt.reload.validated_date).not_to eq(original_date)
    end
    it "redirects to the student show" do
      patch :update, params: valid_params
      expect(response).to redirect_to(student_path(belt.student))
    end
  end

  # describe "#create" do
  #   # let(:valid_params) {       work_plan_domain_id: params.require(:work_plan_domain_id),
  #   it "creates a new WorkPlanSkill with challengeKind attached to a WorkplanDomain and WorkPlan" do
  #     create(:work_plan_domain, work_plan:)
  #     skill = create(:skill, level: work_plan.work_plan_domains.first.level,
  #                            domain: work_plan.work_plan_domains.first.domain)
  #     valid_params = {
  #       skill:,
  #       kind: "exercice",
  #       status: "new",
  #       work_plan_domain_id: work_plan.work_plan_domains.first.id
  #     }
  #     expect do
  #       post :create, params: valid_params
  #     end.to change(work_plan.work_plan_domains.first.work_plan_skills, :count).by(1)
  #   end
  #   it "creates a new WorkPlanSkill with belt Kind attached to a WorkplanDomain and WorkPlan" do
  #     create(:work_plan_domain, work_plan:)
  #     skill = create(:skill, level: work_plan.work_plan_domains.first.level,
  #                            domain: work_plan.work_plan_domains.first.domain)
  #     valid_params = {
  #       skill:,
  #       kind: "ceinture",
  #       status: "new",
  #       work_plan_domain_id: work_plan.work_plan_domains.first.id
  #     }
  #     expect do
  #       post :create, params: valid_params
  #     end.to change(work_plan.work_plan_domains.first.work_plan_skills, :count).by(1)
  #   end
  #   it "creates a new WorkPlanSkill with game Kind attached to a WorkplanDomain and WorkPlan" do
  #     create(:work_plan_domain, work_plan:)
  #     skill = create(:skill, level: work_plan.work_plan_domains.first.level,
  #                            domain: work_plan.work_plan_domains.first.domain)
  #     valid_params = {
  #       skill:,
  #       kind: "jeu",
  #       status: "new",
  #       work_plan_domain_id: work_plan.work_plan_domains.first.id
  #     }
  #     expect do
  #       post :create, params: valid_params
  #     end.to change(work_plan.work_plan_domains.first.work_plan_skills, :count).by(1)
  #   end
  #   it "redirects to the work_plan Show after adding a new WorkPlanSkill" do
  #     create(:work_plan_domain, work_plan:)
  #     skill = create(:skill, level: work_plan.work_plan_domains.first.level,
  #                            domain: work_plan.work_plan_domains.first.domain)
  #     valid_params = {
  #       skill:,
  #       kind: "exercice",
  #       status: "new",
  #       work_plan_domain_id: work_plan.work_plan_domains.first.id
  #     }
  #     post :create, params: valid_params
  #     expect(response).to redirect_to("#{work_plan_path(work_plan)}#challenge_#{work_plan.work_plan_domains.first.work_plan_skills.last.challenge.id}")
  #   end
  # end

  # describe "#eval_update" do
  #   let(:work_plan_domain) { create(:work_plan_domain, work_plan:) }
  #   let(:skill) { create(:skill, level: work_plan_domain.level, domain: work_plan_domain.domain) }
  #   let(:work_plan_skill) { create(:work_plan_skill, skill:, kind: "ceinture", status: "new", work_plan_domain:) }
  #   it "WorkPlanSkillsController#eval_update updates this work_plan_skills status from %w(redo failed redo_OK )" do
  #     valid_params = {
  #       status: %w[redo failed redo_OK].sample,
  #       work_plan_skill_id: work_plan_skill.id
  #     }

  #     patch :eval_update, params: valid_params
  #     work_plan_skill.reload
  #     expect(work_plan_skill.status).to eq(valid_params[:status])
  #   end
  # end
end
