# frozen_string_literal: true

require "rails_helper"
RSpec.describe SkillsController, type: :controller do
  let(:user) { create(:user) }
  let(:grade) { create(:grade, school: user.school) }
  let(:domain1) {create(:domain, grade_id: grade.id)}
  let(:domain2) {create(:domain, grade_id: grade.id)}
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
                10.times do
          create(:skill, domain: domain1, school: user.school)
        end
        get :index
        expect(response.location).to match("http://test.host/classrooms")
      end
    end
    context "when user is logged with at least on classroom" do
      before { sign_in user }

      it "redirect to skills index if user.school has skills" do
        classroom = create(:classroom, user:)
        10.times do
          create(:skill, domain: domain1, school: user.school)
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
      it "creates  and add new valid skill  " do
        classroom = create(:classroom,grade_id: Grade.first.id, user:)
        grade = create(:grade, school: classroom.user.school)
        domain2 = create(:domain, grade: grade)
        expect do
          # :name, :grade, :symbol, :level, :domain)
          post :create, params: { skill: { name: "test", symbol: "⬤", domain_id: domain2.id, level: "1" } }
        end.to change(Skill.where(school: user.school), :count).by(1)
      end
    end
  end
end
