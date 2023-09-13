# frozen_string_literal: true

require "rails_helper"
RSpec.describe SkillsController, type: :controller do
  let(:user) { create(:user) }
  # let(:student) { create(:student, classroom:) }

  describe "#index" do
    context "when user is not logged" do
      # let(:classroom) { create(:classroom, user:) }
      it "redirect to root_path" do
        get :index
        expect(response.location).to match("http://test.host")
      end
    end
    context "when user is logged in but no classroom" do
      # let(:classroom) { create(:classroom, user:) }
      before { sign_in user }
      it "redirect to classroom index" do
        get :index
        expect(response.location).to match("http://test.host/classrooms")
      end
    end
    context "when user is logged with at least on classroom" do
      before { sign_in user }

      it "redirect to skills index if user.school has skills" do
        classroom = create(:classroom, user:)
        10.times do
          create(:skill, grade: classroom.grade, school: user.school)
        end
        get :index
        expect(response).to be_successful
      end
    end
  end

  describe "#create" do
    context "when user is not logged" do
      it "redirect to root_path" do
        post :create
        expect(response.location).to match("http://test.host")
      end
    end
    context "when user is logged" do
      before { sign_in user }
      it "creates a valid new skill with right params " do
        classroom = create(:classroom, user:)
        # :name, :grade, :symbol, :level, :domain)
        post :create, params: { skill: { name: "test", grade: classroom.grade, symbol: "⬤", domain: "Conjugaison", level: "1", school: user.school } }
        expect(response).to be_successful
      end
      it "creates  and add new skill  " do
        classroom = create(:classroom, user:)
        user.school = create(:school)
        expect do
          # :name, :grade, :symbol, :level, :domain)
          post :create, params: { skill: { name: "test", grade: classroom.grade, symbol: "⬤", domain: "Conjugaison", level: "1", school: user.school } }

        end.to change(Skill.where(school: user.school), :count).by(1)
      end
    end
  end
end
