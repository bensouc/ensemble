# frozen_string_literal: true

require "rails_helper"
RSpec.describe MessagesController, type: :controller do
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, conversation_type: %w[ensemble group school classic].sample ) }
  let(:message) { create(:message, conversation: conversation, user: user) }

  before do
    sign_in user
  end

  # describe "GET #show" do
  #   it "assigns the requested message to @message" do
  #     get :show, params: { id: message.id }
  #     expect(assigns(:message)).to eq(message)
  #   end

  #   it "authorizes the message" do
  #     expect(controller).to receive(:authorize).with(message)
  #     get :show, params: { id: message.id }
  #   end

  #   it "renders the show template" do
  #     get :show, params: { id: message.id }
  #     expect(response).to render_template(:show)
  #   end
  # end

  describe "POST #create" do
    context "with valid attributes" do
      it "creates a new message" do
        expect {
          post :create, params: { message: attributes_for(:message), conversation_id: conversation.id }
        }.to change(Message, :count).by(1)
      end

      it "assigns the current user to the message" do
        post :create, params: { message: attributes_for(:message), conversation_id: conversation.id }
        expect(assigns(:message).user).to eq(user)
      end

      it "assigns the conversation to the message" do
        post :create, params: { message: attributes_for(:message), conversation_id: conversation.id }
        expect(assigns(:message).conversation).to eq(conversation)
      end

      it "responds with turbo stream" do
        post :create, params: { message: attributes_for(:message), conversation_id: conversation.id }, format: :turbo_stream
        expect(response.media_type).to eq Mime[:turbo_stream]
      end

      it "redirects to the conversations path" do
        post :create, params: { message: attributes_for(:message), conversation_id: conversation.id }
        expect(response).to redirect_to(conversations_path(conversation_id: conversation.id))
      end
    end

    context "with invalid attributes" do
      it "does not create a new message" do
        expect {
          post :create, params: { message: attributes_for(:message, content: nil), conversation_id: conversation.id }
        }.not_to change(Message, :count)
      end

      it "renders the conversations/show template with unprocessable_entity status" do
        post :create, params: { message: attributes_for(:message, content: nil), conversation_id: conversation.id }
        expect(response).to render_template("conversations/show")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
