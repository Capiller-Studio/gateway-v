# frozen_string_literal: true

module V1
  module Resources
    class Messages < Grape::API
      resource :conversations do
        route_param :conversation_id do
          resource :messages do
            before do
              authenticate_user!
              check_subscription!
              check_api_feature!
            end

            desc 'Get a list of messages in a conversation'
            params do
              optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
              optional :per_page, type: Integer, default: 50, values: 1..100
            end
            get do
              authorize!(:read, Message)
              records, meta = current_account.with_shard do
                conversation = current_account.conversations.find(params[:conversation_id])
                messages = conversation.messages.includes(:sender, :attachments).order(created_at: :asc)
                paginate(messages, per_page: params[:per_page] || 50)
              end

              success(
                data: V1::Entities::MessageEntity.render_as_hash(records),
                meta: meta
              )
            end

            desc 'Create a new message or private note in a conversation'
            params do
              optional :content, type: String, desc: 'Message content', length: { maximum: 50000 }
              optional :private, type: Boolean, default: false, desc: 'Is this a private internal note'
              optional :visibility, type: String, values: %w[global personal]
              optional :attachment_ids, type: Array[String], desc: 'Array of attachment IDs to associate'
            end
            post do
              authorize!(:write, Message)

              if params[:content].blank? && params[:attachment_ids].blank?
                error!({ errors: [{ field: 'content', message: "can't be blank when no attachments provided" }] }, 422)
              end

              visibility_val = if params[:private] == true || params[:visibility] == 'personal'
                                 :personal
                               else
                                 :global
                               end

              message = current_account.with_shard do
                conversation = current_account.conversations.find(params[:conversation_id])
                msg = conversation.messages.create!(
                  account: current_account,
                  inbox: conversation.inbox,
                  sender: current_user,
                  content: params[:content] || '',
                  visibility: visibility_val,
                  source: :api
                )

                if params[:attachment_ids].present?
                  current_account.attachments.where(id: params[:attachment_ids]).update_all(
                    resource_type: 'Message',
                    resource_id: msg.id
                  )
                end

                msg.reload
              end

              success(data: V1::Entities::MessageEntity.render_as_hash(message))
            end

            desc 'Translate a message content into target locale'
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

              # Use Deskbolic Core translation service or clean translated mock for unsupported engines
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
    end
  end
end
