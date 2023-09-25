# frozen_string_literal: true

require "rails_helper"
RSpec.describe ChallengesController, type: :controller do
  let(:user) { create(:user) }
  let(:classroom) { create(:classroom, user:) }
  let(:work_plan) { create(:work_plan, user:) }
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
  end
end
