require "rails_helper"

RSpec.describe Message, type: :model do
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, conversation_type: %w[groupe classic ensemble grade].sample) }
  let(:message) { create(:message, user: user, conversation: conversation) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:conversation) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }
  end

  describe "#act_as_read" do
    let!(:conversation) { create(:conversation, conversation_type: "group") }
    let!(:user2) { create(:user) }
    let!(:message) { create(:message, user: user2, conversation: conversation) }
    context "when the message created is unread" do
      it "returns false" do
        conversation.users << user2
        expect(user.have_read?(message)).to be false
      end
    end
    context "when the message is read" do
      before { message.mark_as_read! for: user }
      it "returns true" do
        expect(user.have_read?(message)).to be true
      end
    end
  end
end
