# frozen_string_literal: true

require "rails_helper"
RSpec.describe WorkPlanSkillsController, type: :controller do
   let(:user) { create(:user) }
  let(:classroom) { create(:classroom, user:) }
  let(:student) { create(:student, classroom:) }
  let(:work_plan) { create(:work_plan, user:, student:) }

  before { sign_in user }

  describe "#create" do
    # let(:valid_params) {       work_plan_domain_id: params.require(:work_plan_domain_id),
    it "creates a new WorkPlanSkill with challengeKind attached to a WorkplanDomain and WorkPlan" do
      create(:work_plan_domain, work_plan:)
      skill = create(:skill, level: work_plan.work_plan_domains.first.level,
                             domain: work_plan.work_plan_domains.first.domain)
      valid_params = {
        skill:,
        kind: "exercice",
        status: "new",
        work_plan_domain_id: work_plan.work_plan_domains.first.id
      }
      expect do
        post :create, params: valid_params
      end.to change(work_plan.work_plan_domains.first.work_plan_skills, :count).by(1)
    end
    it "creates a new WorkPlanSkill with belt Kind attached to a WorkplanDomain and WorkPlan" do
      create(:work_plan_domain, work_plan:)
      skill = create(:skill, level: work_plan.work_plan_domains.first.level,
                             domain: work_plan.work_plan_domains.first.domain)
      valid_params = {
        skill:,
        kind: "ceinture",
        status: "new",
        work_plan_domain_id: work_plan.work_plan_domains.first.id
      }
      expect do
        post :create, params: valid_params
      end.to change(work_plan.work_plan_domains.first.work_plan_skills, :count).by(1)
    end
    it "creates a new WorkPlanSkill with game Kind attached to a WorkplanDomain and WorkPlan" do
      create(:work_plan_domain, work_plan:)
      skill = create(:skill, level: work_plan.work_plan_domains.first.level,
                             domain: work_plan.work_plan_domains.first.domain)
      valid_params = {
        skill:,
        kind: "jeu",
        status: "new",
        work_plan_domain_id: work_plan.work_plan_domains.first.id
      }
      expect do
        post :create, params: valid_params
      end.to change(work_plan.work_plan_domains.first.work_plan_skills, :count).by(1)
    end
    it "redirects to the work_plan_skill work_plan_domain Show after adding a new WorkPlanSkill to it" do
      create(:work_plan_domain, work_plan:)
      skill = create(:skill, level: work_plan.work_plan_domains.first.level,
                             domain: work_plan.work_plan_domains.first.domain)
      valid_params = {
        skill:,
        kind: "exercice",
        status: "new",
        work_plan_domain_id: work_plan.work_plan_domains.first.id
      }
      post :create, params: valid_params
      expect(response).to redirect_to(work_plan_domain_path(WorkPlanSkill.last.work_plan_domain))
    end
  end

  describe "un WPS exercice sans exercice" do
    render_views

    let(:skill) { create(:skill, school: user.school) }
    let(:work_plan_domain) { create(:work_plan_domain, work_plan:) }
    let(:work_plan_skill) do
      create(:work_plan_skill, work_plan_domain:, skill:, kind: "exercice", challenge: nil)
    end

    describe "affichage" do
      it "propose Charger et Créer quand la compétence a des exercices" do
        create(:challenge, user:, skill:)

        get :show, params: { id: work_plan_skill.id }

        expect(response.body).to include(work_plan_skill_pick_challenge_path(work_plan_skill))
        expect(response.body).to include(work_plan_skill_create_empty_challenge_path(work_plan_skill))
      end

      it "ne propose que Créer quand la compétence n'a aucun exercice" do
        get :show, params: { id: work_plan_skill.id }

        expect(response.body).not_to include(work_plan_skill_pick_challenge_path(work_plan_skill))
        expect(response.body).to include(work_plan_skill_create_empty_challenge_path(work_plan_skill))
      end

      it "n'affiche ni Cloner ni un second Charger" do
        create(:challenge, user:, skill:)

        get :show, params: { id: work_plan_skill.id }

        expect(response.body).not_to include("Cloner")
        expect(response.body.scan("Charger").size).to eq(1)
      end
    end

    describe "#pick_challenge" do
      it "renvoie les exercices de la compétence dans l'ordre, dans la frame du WPS" do
        first = create(:challenge, user:, skill:)
        second = create(:challenge, user:, skill:)
        second.move_to_top

        post :pick_challenge, params: { work_plan_skill_id: work_plan_skill.id }, format: :turbo_stream

        expect(response.body).to include("work_plan_skill_#{work_plan_skill.id}")
        expect(response.body.index(second.name)).to be < response.body.index(first.name)
      end

      it "réaffiche les CTA si le dernier exercice a été supprimé entre-temps" do
        post :pick_challenge, params: { work_plan_skill_id: work_plan_skill.id }, format: :turbo_stream

        expect(response).to be_successful
        expect(response.body).to include(work_plan_skill_create_empty_challenge_path(work_plan_skill))
      end

      it "écarte les exercices de ceinture" do
        create(:challenge, user:, skill:, for_belt: true)
        classic = create(:challenge, user:, skill:)

        post :pick_challenge, params: { work_plan_skill_id: work_plan_skill.id }, format: :turbo_stream

        expect(assigns(:challenges)).to eq([classic])
      end
    end

    describe "#create_empty_challenge" do
      it "crée un exercice à rédiger, en fin de liste, et l'attache au WPS" do
        create(:challenge, user:, skill:)

        expect do
          post :create_empty_challenge, params: { work_plan_skill_id: work_plan_skill.id },
                                        format: :turbo_stream
        end.to change(Challenge, :count).by(1)

        created = Challenge.last
        expect(work_plan_skill.reload.challenge).to eq(created)
        expect(created.position).to eq(2)
        expect(created.user).to eq(user)
      end

      it "ne casse pas quand le nom construit sur le compteur est déjà pris" do
        create(:challenge, user:, skill:, name: "#{skill.name} 2-NEW")

        post :create_empty_challenge, params: { work_plan_skill_id: work_plan_skill.id },
                                      format: :turbo_stream

        expect(work_plan_skill.reload.challenge).to be_present
      end
    end

    describe "#update" do
      it "attache l'exercice choisi à un WPS qui n'en avait pas" do
        challenge = create(:challenge, user:, skill:)

        patch :update, params: { id: work_plan_skill.id, work_plan_skill: { challenge_id: challenge.id } },
                       format: :turbo_stream

        expect(work_plan_skill.reload.challenge).to eq(challenge)
      end
    end
  end

  describe "#eval_update" do
    let(:work_plan_domain) { create(:work_plan_domain, work_plan:) }
    let(:skill) { create(:skill, level: work_plan_domain.level, domain: work_plan_domain.domain) }
    let(:work_plan_skill) { create(:work_plan_skill, skill:, kind: "ceinture", status: "new", work_plan_domain:) }
    it "WorkPlanSkillsController#eval_update updates this work_plan_skills status from %w(redo failed redo_OK )" do
      valid_params = {
        status: %w[redo failed redo_OK].sample,
        work_plan_skill_id: work_plan_skill.id
      }

      patch :eval_update, params: valid_params
      work_plan_skill.reload
      expect(work_plan_skill.status).to eq(valid_params[:status])
    end
  end
end
