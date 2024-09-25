require "rails_helper"

RSpec.describe ConversationsController, type: :controller do
  let(:user) { create(:user) }
  let(:user2) { create(:user, school: user.school) }
  let(:school_conversation) { create(:conversation, conversation_type: "school") }
  let(:ensemble_conversation) { create(:conversation, conversation_type: "ensemble") }
  let(:classic_conversation) { create(:conversation, conversation_type: "classic") }
  let(:message) { create(:message, conversation: classic_conversation) }

  before do
    sign_in user
    allow(Conversation).to receive(:find_or_create_school_conversation).and_return(school_conversation)
    allow(Conversation).to receive(:find_or_create_ensemble).and_return(ensemble_conversation)
  end

  describe "GET #index" do
    context "when conversation_id is present" do
      context "and classic_conversation is not nil" do
        before do
          allow(user).to receive(:classic_conversations).and_return([classic_conversation])
        end

        it "assigns the requested conversation to @conversation" do
          get :index, params: { conversation_id: classic_conversation.id }
          expect(assigns(:conversation)).to eq(classic_conversation)
        end
      end

      context "and classic_conversation is nil" do
        before do
          allow(user).to receive(:classic_conversations).and_return([])
        end

        it "does not assign a conversation to @conversation" do
          get :index
          expect(assigns(:conversation)).to eq(school_conversation)
        end
      end
    end

    context "when conversation_id is not present" do
      before do
        allow(user).to receive(:classic_conversations).and_return([classic_conversation])
      end

      it "assigns the school conversation to @conversation" do
        get :index
        expect(assigns(:conversation)).to eq(school_conversation)
      end
    end

    it "assigns the school conversation to @school_conversation" do
      get :index
      expect(assigns(:school_conversation)).to eq(school_conversation)
    end

    it "assigns the ensemble conversation to @ensemble_conversation" do
      get :index
      expect(assigns(:ensemble_conversation)).to eq(ensemble_conversation)
    end
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "POST #contact_user" do
    it "finds the contact user" do
      post :contact_user, params: { contact_id: user2.id }
      expect(assigns(:contact)).to eq(user2)
    end

    it "creates or finds  conversation" do
      post :contact_user, params: { contact_id: user2.id }
      expect(assigns(:conversation).class).to eq(Conversation)
    end

    it "ensures the conversation is of type classic" do
      post :contact_user, params: { contact_id: user2.id }
      expect(assigns(:conversation).conversation_type).to eq("classic")
    end

    it "ensures the conversation includes both current_user and contact" do
      post :contact_user, params: { contact_id: user2.id }
      expect(assigns(:conversation).users).to include(user, user2)
    end

    it "redirects to the conversations path with the conversation_id" do
      post :contact_user, params: { contact_id: user2.id }
      expect(response).to redirect_to(conversations_path(conversation_id: assigns(:conversation).id))
    end
  end
end
