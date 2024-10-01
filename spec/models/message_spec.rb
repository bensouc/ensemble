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

  # describe "#mark_as_read!" do
  #   let!(:message2) { create(:message, user: user, conversation: conversation) }
  #   it "marks the message as read for the user" do
  #     message2.mark_as_read!(user)
  #     expect(message2.read_by?(user)).to be true
  #   end
  # end
end
