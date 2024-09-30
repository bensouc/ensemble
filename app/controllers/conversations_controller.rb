# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [:show, :edit, :update, :destroy, :add_user]
  before_action :set_index_conversations, only: [:index]
  # after_action :verify_authorized, except: :index

  def index
    skip_policy_scope
    # @user = User.includes([:avatar_attachment]).find(current_user.id)
    if params[:conversation_id].present?
      @conversation = Conversation.includes([:messages]).find(params[:conversation_id])
      @collegue_not_in_conversation = @collegues_with_avatars.reject { |collegue| @conversation.users.include?(collegue) }
      @conversation.mark_as_read!(current_user)
    else
      @conversation = @school_conversation || @school_conversations.sort_by(&:id).first
      @conversation.mark_as_read!(current_user)
    end
  end

  def contact_user
    @contact = User.find(params[:contact_id])
    # la creation d'un conversation doit se faire avec comme paramas le conversation_type ()
    skip_authorization
    @conversation = Conversation.find_or_create_classic_conversation(current_user, @contact)
    @collegue_not_in_conversation = current_user.collegues_with_avatars.reject { |collegue| @conversation.users.include?(collegue) }
    respond_to do |format|
      format.html { redirect_to conversations_path(conversation_id: @conversation.id) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("conversation", partial: "conversations/conversation",
                                                                  locals: { conversation: @conversation, collegue_not_in_conversation: @collegue_not_in_conversation })
      }
    end
  end

  def show
    @collegue_not_in_conversation = current_user.collegues_with_avatars.reject { |collegue| @conversation.users.include?(collegue) }
  end

  def add_user
    @new_user = User.find(params[:new_user_id])
    @conversation.add_user!(@new_user)
    @collegue_not_in_conversation = current_user.collegues_with_avatars.reject { |collegue| @conversation.users.include?(collegue) }
    respond_to do |format|
      format.html { redirect_to conversations_path(conversation_id: @conversation.id) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("conversation", partial: "conversations/conversation",
                                                                  locals: { conversation: @conversation, collegue_not_in_conversation: @collegue_not_in_conversation })
      }
    end
  end

  def edit
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

  def set_index_conversations
    if current_user.admin?
      @school_conversations = Conversation.where(conversation_type: "school")
    else
      @school_conversation = Conversation.find_or_create_school_conversation(current_user)
    end
    @ensemble_conversation = Conversation.find_or_create_ensemble(current_user) unless current_user.admin?
    @user_conversations = current_user.classic_and_group_conversations
    @collegues_with_avatars = current_user.collegues_with_avatars
    @ensemble_conversations = Conversation.ensemble if current_user.admin?
  end

  def conversation_params
    params.require(:conversation).permit(:conversation_type, :user_id)
  end
end
