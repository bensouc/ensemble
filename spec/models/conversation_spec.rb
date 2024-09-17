require "rails_helper"

RSpec.describe Conversation, type: :model do
  let(:user) { create(:user) }

  describe "associations" do
    it { is_expected.to have_many(:messages).dependent(:destroy) }
    it { is_expected.to have_many(:user_conversations).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_conversations) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:conversation_type) }
    it { is_expected.to validate_inclusion_of(:conversation_type).in_array(%w[ensemble grade school classic]) }
  end

  describe ".find_or_create_ensemble" do
    context "when the conversation exists" do
      let!(:conversation) { create(:conversation, conversation_type: "ensemble") }

      before do
        conversation.users << user
      end

      it "returns the existing conversation" do
        expect(Conversation.find_or_create_ensemble(user)).to eq(conversation)
      end
    end

    context "when the conversation does not exist" do
      it "creates a new conversation" do
        expect {
          Conversation.find_or_create_ensemble(user)
        }.to change { Conversation.count }.by(1)
      end

      it "associates the user with the new conversation" do
        conversation = Conversation.find_or_create_ensemble(user)
        expect(conversation.users).to include(user)
      end
    end
  end
end
