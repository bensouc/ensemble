# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :set_message, only: %i[show edit]

  def show
    authorize @message
  end

  def create
    @message = Message.new(message_params)
    @message.user = current_user
    @conversation = Conversation.find(params[:conversation_id])
    @message.conversation = @conversation
    authorize @message
    if @message.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(:messages, partial: "messages/message",
                                                        locals: { message: @message, user: current_user })
        end
        format.html { redirect_to conversations_path(conversation_id: @conversation.id) }
      end
    else
      render "conversations/show", status: :unprocessable_entity,
        locals: { collegue_not_in_conversation: current_user.collegues_with_avatars.reject { |collegue| @conversation.users.include?(collegue) },
                  conversation: @conversation }
    end
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
