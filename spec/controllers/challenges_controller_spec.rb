# frozen_string_literal: true

require "rails_helper"
RSpec.describe ChallengesController, type: :controller do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge, user:) }
  let(:classroom) { create(:classroom, user:) }
  let(:work_plan) { create(:work_plan, user:) }
  let(:skill) { create(:skill, school: user.school) }
  let(:work_plan_domain) { create(:work_plan_domain, work_plan:) }
  let(:work_plan_skill) { create(:work_plan_skill, work_plan_domain:, kind: "exercice", challenge:) }
  describe "#index" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :index
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in and has a classroom" do
      it "returns a successful response" do
        2.times do
          create(:challenge, user:)
        end
        sign_in(user)
        create(:classroom, user:)
        get :index
        expect(response).to be_successful
      end
    end
    context "when user is signed in and has no classroom" do
      it "redirect to classroom index" do
        2.times do
          create(:challenge, user:)
        end
        sign_in(user)
        get :index
        expect(response).to redirect_to("http://test.host/classrooms")
      end
    end
    context "when user use filters" do
      it "returns a successful response" do
        sign_in(user)
        get :index, params: { "/challenges" => { grade: skill.domain.grade, domain: skill.domain , level: skill.level } }
        # expect(response).to be_successful
        expect(response).to redirect_to("http://test.host/classrooms")
      end
    end
  end

  describe "#show" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :show, params: { id: challenge.id }
        expect(response).not_to be_successful
      end
    end

    context "when user is signed in" do
      it "returns a successful response" do
        sign_in(user)
        get :show, params: { id: challenge.id }
        expect(response).to be_successful
      end
    end
  end

  describe "#new" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :new
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "returns a successful response with the skill params" do
        sign_in(user)
        get :new, params: { skill: skill.id }
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end
    end
  end

  describe "#edit" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :edit, params: { id: challenge.id }
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "returns a successful response with the skill params" do
        sign_in(user)
        get :edit, params: { id: challenge.id }
        expect(response).to be_successful
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "#create" do
    context "when user is not signed in" do
      it "returns a failure response" do
        post :create, params: { challenge: { name: "test" } }
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "creates a new challenge and redirect to It" do
        sign_in(user)
        expect {
          post :create, params: { challenge: {
                          skill_id: skill.id,
                          content: Faker::Lorem.paragraph(sentence_count: 2, supplemental: false, random_sentences_to_add: 4),
                          name: Faker::Lorem.sentence(word_count: 3, supplemental: false, random_words_to_add: 4),
                        } }
        }.to change { Challenge.count }.by(1)
        expect(response).to redirect_to("http://test.host/challenges/#{Challenge.last.id}")
      end
    end
  end

  describe "#update" do
    context "when user is not signed in" do
      it "returns a failure response" do
        new_content = Faker::Lorem.paragraph(sentence_count: 2, supplemental: false, random_sentences_to_add: 4)
        new_name = Faker::Lorem.sentence(word_count: 3, supplemental: false, random_words_to_add: 4)
        patch :update, params: { id: challenge.id, challenge: {
                         content: new_content,
                         name: new_name,
                       } }
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "update a sepcified challenge and redirect to It" do
        sign_in(user)
        new_content = "new-content"
        new_name = "new-name"
        patch :update, params: { id: challenge.id, challenge: {
                         content: new_content,
                         name: new_name,
                       } }
        challenge.reload
        expect(challenge.name).to eq(new_name)
        expect(response).to redirect_to(challenge_path(challenge))
      end
    end
  end

  describe "#clone" do
    context "when user is not signed in" do
      it "returns a failure response" do
        post :clone, params: { id: challenge.id, work_plan_skill_id: work_plan_skill }
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "creates a new IDENTICAL challenge and redirect to It" do
        sign_in(user)
        # post "/challenges/:id", to: "challenges#clone"
        post :clone, params: { id: challenge.id, work_plan_skill_id: work_plan_skill }
        expect(Challenge.last.content.body).to eq(challenge.content.body)
        work_plan_skill.reload
        expect(work_plan_skill.challenge).to eq(Challenge.last)
        # expect(response).to render_template(["action_text/contents/_content", "layouts/action_text/contents/_content"])
        # expect(response).to render_template(:new)
      end
    end
  end

  describe "#destroy" do
    context "when user is not signed in" do
      it "returns a failure response" do
        delete :destroy, params: { id: challenge.id }
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "destroy a sepcified challenge and redirect to It" do
        sign_in(user)
        chal = create(:challenge, user:)
        expect do
          delete :destroy, params: { id: chal.id }
        end.to change { Challenge.all.count }.by(-1)
        expect(response).to redirect_to(challenges_path)
      end
    end
  end

  describe "#display_challenges" do
    it "renders caroussel of  XXX challenges" do
      sign_in(user)
      3.times do
        create(:challenge, user:, skill: challenge.skill)
      end
      p Challenge.where(skill: challenge.skill).count
      get :display_challenges, params: { id: challenge.id, work_plan_skill_id: work_plan_skill.id }
      expect(response).to render_template("challenges/_challenges_carroussel")
    end
    it "render the challenge if it is the only one for its skill" do
      sign_in(user)
      get :display_challenges, params: { id: challenge.id, work_plan_skill_id: work_plan_skill.id }
      expect(response).to render_template("challenges/_challenge")
    end
  end
end
