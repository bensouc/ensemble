# frozen_string_literal: true

require "rails_helper"
RSpec.describe ChallengesController, type: :controller do
  let(:user) { create(:user) }
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
end
