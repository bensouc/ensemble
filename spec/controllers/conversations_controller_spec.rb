require "rails_helper"

RSpec.describe ConversationsController, type: :controller do
  let(:user) { create(:user) }
  let(:user2) { create(:user, school: user.school) }
  let(:school_conversation) { create(:conversation, conversation_type: "school") }
  let(:ensemble_conversation) { create(:conversation, conversation_type: "ensemble") }
  let(:classic_conversation) { create(:conversation, conversation_type: "classic") }
  let(:message) { create(:message, conversation: classic_conversation) }
  let(:conversation) { create(:conversation) }

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

  describe "GET #show" do
    let!(:conversation) { create(:conversation, conversation_type: "classic") }
    it "assigns the requested conversation to @conversation" do
      get :show, params: { id: conversation.id }
      expect(assigns(:conversation)).to eq(conversation)
    end

    it "renders the show template" do
      get :show, params: { id: conversation.id }
      expect(response).to render_template(:show)
    end
  end

  describe "GET #edit" do
    let!(:conversation_show) { create(:conversation, conversation_type: "classic") }
    it "assigns the requested conversation to @conversation" do
      get :edit, params: { id: conversation_show.id }
      expect(assigns(:conversation)).to eq(conversation_show)
    end

    it "renders the edit template" do
      get :edit, params: { id: conversation_show.id }
      expect(response).to render_template(:edit)
    end
  end

  describe "PATCH #update" do
    let!(:new_conversation) { create(:conversation, conversation_type: "group") }
    context "with valid attributes" do
      it "updates the conversation" do
        patch :update, params: { id: new_conversation.id, conversation: { name: "New Name" } }
        new_conversation.reload
        expect(new_conversation.name).to eq("New Name")
      end

      it "redirects to the conversation" do
        patch :update, params: { id: new_conversation.id, conversation: { name: "New Name" } }
        new_conversation.reload
        expect(response).to redirect_to("http://test.host/conversations?conversation=#{new_conversation.id}")
      end
    end

    context "with invalid attributes" do
      it "does not update the conversation" do
        patch :update, params: { id: new_conversation.id, conversation: { name: nil } }
        new_conversation.reload
        expect(new_conversation.name).not_to eq(nil)
      end

      it "re-renders the edit template" do
        patch :update, params: { id: new_conversation.id, conversation: { name: nil } }
        expect(response).to redirect_to("http://test.host/conversations?conversation=#{new_conversation.id}")
      end
    end
  end

  describe "DELETE #remove_user" do
    it "removes the current user from the conversation" do
      conversation.users << user
      expect(conversation.users.include?(user)).to eq(true)
      delete :remove_user, params: { id: conversation.id }
      conversation.reload
      expect(conversation.users.include?(user)).to eq(false)
    end
  end

  describe "POST #add_user" do
    let(:conversation) { create(:conversation, conversation_type: "classic") }
    let(:new_user) { create(:user) }
    let(:current_user) { create(:user) }

    before do
      allow(controller).to receive(:current_user).and_return(current_user)
      allow(User).to receive(:find).with(any_args).and_return(new_user)
      allow(conversation).to receive(:add_user!).with(new_user).and_return(true)
      allow(current_user).to receive(:collegues_with_avatars).and_return([new_user])
      allow(conversation.users).to receive(:include?).and_return(false)
    end

    it "adds a new user to the conversation" do
      post :add_user, params: { id: conversation.id, new_user_id: new_user.id }
      conversation.reload
      expect(conversation.users.include?(new_user)).to eq(true)
    end

    it "redirects to conversations path with HTML format" do
      post :add_user, params: { id: conversation.id, new_user_id: new_user.id }, format: :html
      expect(response).to redirect_to(conversations_path(conversation_id: conversation.id))
    end

    it "renders turbo stream with Turbo Stream format" do
      post :add_user, params: { id: conversation.id, new_user_id: new_user.id }, format: :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
