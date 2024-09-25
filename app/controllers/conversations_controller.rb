# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [:show, :edit, :update, :destroy]
  # after_action :verify_authorized, except: :index

  def index
    skip_policy_scope
    @school_conversation = Conversation.find_or_create_school_conversation(current_user)
    @ensemble_conversation = Conversation.find_or_create_ensemble(current_user)
    @user_conversations = current_user.classic_and_group_conversations
    @collegues_with_avatars = current_user.collegues_with_avatars
    # @user = User.includes([:avatar_attachment]).find(current_user.id)
    if params[:conversation_id].present?
      @conversation = Conversation.includes([:messages]).find(params[:conversation_id])
    else
      @conversation = @school_conversation
    end
  end

  def contact_user
    @contact = User.find(params[:contact_id])
    # la creation d'un conversation doit se faire avec comme paramas le conversation_type ()
    skip_authorization
    @conversation = Conversation.find_or_create_classic_conversation(current_user, @contact)
    redirect_to conversations_path(conversation_id: @conversation.id)
    # respond_to do |format|
    # format.html {redirect_to conversations_path(conversation_id: @conversation.id)}
    # format.turbo_stream {

    # }
    # end
  end

  def show
  end

  def add_user
    @new_user = User.find(params[:user_id])
  end

  def edit

    # binding.pry
  end

  def update
    @conversation.update(update_params)
    respond_to do |format|
      format.html { redirect_to conversations_path(conversation: @conversation.id) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("conversation_#{@conversation.id}_name",
                                                  partial: "conversations/name",
                                                  locals: { conversation: @conversation })
      }
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
    authorize @conversation
  end

  def update_params
    params.require(:conversation).permit(:name)
  end

  def conversation_params
    params.require(:conversation).permit(:conversation_type, :user_id)
  end
end
