# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [:show, :edit, :update, :destroy]
  # after_action :verify_authorized, except: :index

  def index
    skip_policy_scope
    @school_conversation = Conversation.find_or_create_school_conversation(current_user)
    @ensemble_conversation = Conversation.find_or_create_ensemble(current_user)
    @user_conversation = current_user.classic_conversations
  end

  def create
    # la creation d'un conversation doit se faire avec comme paramas le conversation_type ()
    @conversation = Conversation.new(conversation_params)
  end

  def show
  end
  def add_user
    @new_user = User.find(params[:user_id])
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
    authorize @conversation
  end
  def conversation_params
    params.require(:conversation).permit(:conversation_type, :user_id)
  end
end
