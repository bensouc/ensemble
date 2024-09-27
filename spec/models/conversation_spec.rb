require "rails_helper"

RSpec.describe Conversation, type: :model do
  let(:user) { create(:user) }

  describe "associations" do
    it { is_expected.to have_many(:messages).dependent(:destroy) }
    it { is_expected.to have_many(:user_conversations).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_conversations) }
  end

  describe "validations" do
    let!(:classic_conversation) { create(:conversation, conversation_type: "classic") }
    let!(:school_conversation) { create(:conversation, conversation_type: "school") }
    let!(:ensemble_conversation) { create(:conversation, conversation_type: "ensemble") }
    it { is_expected.to validate_presence_of(:conversation_type) }
    it "validates inclusion of conversation_type in specific values" do
      expect(classic_conversation).to validate_inclusion_of(:conversation_type).in_array(%w[ensemble group school classic])
      expect(school_conversation).to validate_inclusion_of(:conversation_type).in_array(%w[ensemble group school classic])
      expect(ensemble_conversation).to validate_inclusion_of(:conversation_type).in_array(%w[ensemble group school classic])
    end
  end

  describe "scopes" do
    let!(:classic_conversation) { create(:conversation, conversation_type: "classic") }
    let!(:school_conversation) { create(:conversation, conversation_type: "school") }
    let!(:ensemble_conversation) { create(:conversation, conversation_type: "ensemble") }

    it "returns classic conversations" do
      expect(Conversation.classic).to include(classic_conversation)
      expect(Conversation.classic).not_to include(school_conversation, ensemble_conversation)
    end

    it "returns school conversations" do
      expect(Conversation.school).to include(school_conversation)
      expect(Conversation.school).not_to include(classic_conversation, ensemble_conversation)
    end

    it "returns ensemble conversations" do
      expect(Conversation.ensemble).to include(ensemble_conversation)
      expect(Conversation.ensemble).not_to include(classic_conversation, school_conversation)
    end
  end
  describe "instance methods" do
    let!(:conversation) { create(:conversation, conversation_type: "classic") }
    context "#is_group?" do
      it "returns true if conversation type is group" do
        conversation.update(conversation_type: "group")
        expect(conversation.is_group?).to be true
      end

      it "returns false if conversation type is not group" do
        conversation.update(conversation_type: "classic")
        expect(conversation.is_group?).to be false
      end
    end

    context "#is_school?" do
      it "returns true if conversation type is school" do
        conversation.update(conversation_type: "school")
        expect(conversation.is_school?).to be true
      end

      it "returns false if conversation type is not school" do
        conversation.update(conversation_type: "classic")
        expect(conversation.is_school?).to be false
      end
    end

    context "#is_classic?" do
      it "returns true if conversation type is classic" do
        conversation.update(conversation_type: "classic")
        expect(conversation.is_classic?).to be true
      end

      it "returns false if conversation type is not classic" do
        conversation.update(conversation_type: "school")
        expect(conversation.is_classic?).to be false
      end
    end

    context "#is_ensemble?" do
      it "returns true if conversation type is ensemble" do
        conversation.update(conversation_type: "ensemble")
        expect(conversation.is_ensemble?).to be true
      end

      it "returns false if conversation type is not ensemble" do
        conversation.update(conversation_type: "classic")
        expect(conversation.is_ensemble?).to be false
      end
    end

    context "#add_user!" do
      it "adds a user to the conversation and changes the type to group" do
        expect {
          conversation.add_user!(user)
        }.to change { conversation.users.count }.by(1)
        expect(conversation.conversation_type).to eq("group")
      end
    end
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
