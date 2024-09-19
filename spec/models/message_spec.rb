require "rails_helper"

RSpec.describe Message, type: :model do
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation) }
  let(:message) { create(:message, user: user, conversation: conversation) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:conversation) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }
  end

  describe "#read?" do
    context "when the message is read" do
      before { message.update(read: true) }

      it "returns true" do
        expect(message.read?).to be true
      end
    end

    context "when the message is unread" do
      before { message.update(read: false) }

      it "returns false" do
        expect(message.read?).to be false
      end
    end
  end

  describe "#read!" do
    it "marks the message as read" do
      message.read!
      expect(message.read).to be true
    end
  end
end
