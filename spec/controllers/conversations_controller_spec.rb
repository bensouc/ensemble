require "rails_helper"

RSpec.describe ConversationsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:conversation) { create(:conversation) }

  before do
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { id: conversation.id }
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Conversation" do
        expect {
          post :create, params: { conversation: { conversation_type: "school", user_id: user.id } }
        }.to change(Conversation, :count).by(1)
      end

      it "redirects to the created conversation" do
        post :create, params: { conversation: { conversation_type: "school", user_id: user.id } }
        expect(response).to redirect_to(Conversation.last)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e., to display the 'new' template)" do
        post :create, params: { conversation: { conversation_type: nil } }
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        { conversation_type: "ensemble", user_id: user.id }
      }

      it "updates the requested conversation" do
        put :update, params: { id: conversation.id, conversation: new_attributes }
        conversation.reload
        expect(conversation.conversation_type).to eq("ensemble")
      end

      it "redirects to the conversation" do
        put :update, params: { id: conversation.id, conversation: new_attributes }
        expect(response).to redirect_to(conversation)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e., to display the 'edit' template)" do
        put :update, params: { id: conversation.id, conversation: { conversation_type: nil } }
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested conversation" do
      conversation = create(:conversation)
      expect {
        delete :destroy, params: { id: conversation.id }
      }.to change(Conversation, :count).by(-1)
    end

    it "redirects to the conversations list" do
      delete :destroy, params: { id: conversation.id }
      expect(response).to redirect_to(conversations_url)
    end
  end

  describe "POST #add_user" do
    it "adds a user to the conversation" do
      post :add_user, params: { id: conversation.id, user_id: other_user.id }
      expect(conversation.users).to include(other_user)
    end

    it "redirects to the conversation" do
      post :add_user, params: { id: conversation.id, user_id: other_user.id }
      expect(response).to redirect_to(conversation)
    end
  end
end
