# frozen_string_literal: true

module V1
  module Resources
    class Messages < Grape::API
      # Nested under conversations: /v1/conversations/:conversation_id/messages
      resource :conversations do
        route_param :conversation_id do
          resource :messages do
            before do
              authenticate_user!
              check_subscription!
              check_api_feature!
            end

            desc 'Get a list of messages in a conversation (supports cursor and offset pagination)'
            params do
              optional :before_id, type: String, desc: 'Fetch messages older than ID'
              optional :after_id, type: String, desc: 'Fetch messages newer than ID'
              optional :limit, type: Integer, default: 50, values: 1..100
              optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
              optional :per_page, type: Integer, default: 50, values: 1..100
              optional :visibility, type: String, values: %w[global personal]
            end
            get do
              authorize!(:read, Message)
              records, meta = current_account.with_shard do
                conversation = current_account.conversations.find(params[:conversation_id])
                messages = conversation.messages.includes(:sender, :attachments, :reactions)
                messages = messages.where(visibility: params[:visibility]) if params[:visibility].present?

                if params[:before_id].present? || params[:after_id].present?
                  paginate_cursor(messages.order(created_at: :asc), limit: params[:limit] || 50)
                else
                  paginate(messages.order(created_at: :asc), per_page: params[:per_page] || 50)
                end
              end

              success(
                data: V1::Entities::MessageEntity.render_as_hash(records),
                meta: meta
              )
            end

            desc 'Create a new message or private note in a conversation'
            params do
              optional :content, type: String, desc: 'Message content', length: { maximum: 50000 }
              optional :response, type: String, desc: 'Alternative alias for content', length: { maximum: 50000 }
              optional :private, type: Boolean, default: false, desc: 'Is this a private internal note'
              optional :visibility, type: String, values: %w[global personal]
              optional :resolve_conversation, type: Boolean, default: false, desc: 'Resolve conversation after sending'
              optional :attachment_ids, type: Array[String], desc: 'Array of attachment IDs to associate'
            end
            post do
              authorize!(:write, Message)

              text_content = params[:content].presence || params[:response].presence
              if text_content.blank? && params[:attachment_ids].blank?
                error!({
                  success: false,
                  errors: [{ code: 'validation_error', field: 'content', message: "can't be blank when no attachments provided" }]
                }, 422)
              end

              visibility_val = if params[:private] == true || params[:visibility] == 'personal'
                                 'personal'
                               else
                                 'global'
                               end

              resolve_after_send = [true, 'true', '1', 1].include?(params[:resolve_conversation])

              message = current_account.with_shard do
                conversation = current_account.conversations.find(params[:conversation_id])

                unless conversation.assigned?
                  conversation.assign!(current_user)
                end

                attachments = if params[:attachment_ids].present?
                                current_account.attachments.where(id: params[:attachment_ids]).to_a
                              else
                                []
                              end

                messages = ::Messages::MessageCreator.call(
                  conversation: conversation,
                  content: text_content,
                  attachments: attachments,
                  sender: current_user,
                  visibility: visibility_val,
                  source: :api
                )

                msg = messages.first || conversation.messages.last

                conversation.update!(status: :resolved) if resolve_after_send

                msg
              end

              status 201
              success(data: V1::Entities::MessageEntity.render_as_hash(message))
            end

            desc 'Translate message content into target locale'
            params do
              requires :id, type: String, desc: 'Message ID', allow_blank: false
              requires :target_locale, type: String, values: Core::SUPPORTED_LOCALES.map(&:to_s), desc: 'Target locale code'
            end
            post ':id/translate' do
              authorize!(:read, Message)
              message = current_account.with_shard do
                conversation = current_account.conversations.find(params[:conversation_id])
                conversation.messages.find(params[:id])
              end

              translated_text = message.content
              if defined?(Ai::TranslationService)
                translated_text = Ai::TranslationService.call(text: message.content, target_locale: params[:target_locale]) rescue message.content
              end

              success(
                data: {
                  message_id: message.id,
                  original_content: message.content,
                  translated_content: translated_text,
                  target_locale: params[:target_locale]
                }
              )
            end
          end
        end
      end

      # Standalone message resource: /v1/messages/:id
      resource :messages do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        route_param :id do
          desc 'Get a single message'
          get do
            authorize!(:read, Message)
            message = current_account.with_shard do
              current_account.messages.includes(:sender, :attachments, :reactions).find(params[:id])
            end
            success(data: V1::Entities::MessageEntity.render_as_hash(message))
          end

          # NOTE: Message deletion endpoint is commented out to prevent timeline/sync issues
          # desc 'Delete a message'
          # delete do
          #   authorize!(:destroy, Message)
          #   current_account.with_shard do
          #     msg = current_account.messages.find(params[:id])
          #     msg.destroy!
          #   end
          #   success(message: 'Message deleted successfully')
          # end

          desc 'Add an emoji reaction to message'
          params do
            requires :emoji, type: String, allow_blank: false, desc: 'Emoji symbol or code'
          end
          post :reactions do
            authorize!(:write, Message)
            reaction = current_account.with_shard do
              msg = current_account.messages.find(params[:id])
              existing = msg.reactions.find_by(sender: current_user, emoji: params[:emoji])
              existing || msg.reactions.create!(
                account: current_account,
                sender: current_user,
                emoji: params[:emoji]
              )
            end

            success(data: { id: reaction.id, emoji: reaction.emoji, message_id: reaction.message_id })
          end

          desc 'Remove an emoji reaction from message'
          params do
            requires :emoji, type: String, allow_blank: false, desc: 'Emoji to remove'
          end
          delete 'reactions/:emoji' do
            authorize!(:write, Message)
            target_emoji = CGI.unescape(params[:emoji].to_s)
            current_account.with_shard do
              msg = current_account.messages.find(params[:id])
              msg.reactions.where(sender: current_user, emoji: [params[:emoji], target_emoji].uniq).destroy_all
            end

            success(message: 'Reaction removed successfully')
          end

          desc 'Remove an emoji reaction from message using query param'
          params do
            requires :emoji, type: String, allow_blank: false, desc: 'Emoji to remove'
          end
          delete :reactions do
            authorize!(:write, Message)
            target_emoji = CGI.unescape(params[:emoji].to_s)
            current_account.with_shard do
              msg = current_account.messages.find(params[:id])
              msg.reactions.where(sender: current_user, emoji: [params[:emoji], target_emoji].uniq).destroy_all
            end

            success(message: 'Reaction removed successfully')
          end
        end
      end
    end
  end
end
