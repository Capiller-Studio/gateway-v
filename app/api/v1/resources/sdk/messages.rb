# frozen_string_literal: true

module V1
  module Resources
    module Sdk
      class Messages < Grape::API
        segment 'conversations/:conversation_id' do
          resource :messages do
            before do
              authenticate_sdk_customer!
              @conversation = with_sdk_shard do
                current_customer.conversations.where(inbox: current_inbox).find_by(id: params[:conversation_id])
              end

              unless @conversation
                failure(errors: [{ code: "conversation_not_found", message: "Conversation not found" }], status: 404)
              end
            end

            desc 'Get conversation messages'
            params do
              optional :limit, type: Integer, default: 30
              optional :before_id, type: String, desc: 'Fetch messages created before this message ID'
              optional :after_id, type: String, desc: 'Fetch messages created after this message ID (catch-up)'
            end
            get do
              relation = with_sdk_shard do
                @conversation.messages.global
                             .includes(:sender, attachments: { file_attachment: :blob })
                             .order(created_at: :desc)
              end

              messages, meta = paginate_cursor(
                relation,
                limit: params[:limit],
                before_id: params[:before_id],
                after_id: params[:after_id]
              )

              # Reverse so they are returned in chronological order for UI display
              ordered_messages = messages.reverse

              success(
                data: V1::Entities::Sdk::MessageEntity.render_as_hash(ordered_messages),
                meta: meta
              )
            end

            desc 'Send message in conversation'
            params do
              optional :content, type: String
              optional :attachment_ids, type: Array[String], default: []
              optional :client_message_id, type: String, desc: 'Client-generated UUID for idempotency'
              at_least_one_of :content, :attachment_ids
            end
            post do
              # Idempotency check
              if params[:client_message_id].present?
                existing = with_sdk_shard do
                  @conversation.messages.where("data->>'client_message_id' = ?", params[:client_message_id]).first
                end
                if existing
                  return success(data: V1::Entities::Sdk::MessageEntity.render_as_hash(existing))
                end
              end

              resolved_attachments = []
              if params[:attachment_ids].present?
                unless current_channel.attachments_enabled?
                  failure(errors: [{ code: "attachments_disabled", message: "File attachments are disabled for this channel" }], status: 403)
                end

                params[:attachment_ids].each do |signed_id|
                  blob = ActiveStorage::Blob.find_signed(signed_id) rescue nil
                  resolved_attachments << blob if blob
                end
              end

              message = with_sdk_shard do
                msg = ::Channels::WebWidgets::MessageCreator.call(
                  account: current_account,
                  inbox: current_inbox,
                  conversation: @conversation,
                  sender: current_customer,
                  content: params[:content],
                  attachments: resolved_attachments
                )

                if params[:client_message_id].present?
                  msg.update_column(:data, msg.data.merge("client_message_id" => params[:client_message_id]))
                end

                # Re-fetch with eager loaded associations
                ::Message.includes(:sender, attachments: { file_attachment: :blob }).find(msg.id)
              end

              status 201
              success(data: V1::Entities::Sdk::MessageEntity.render_as_hash(message))
            end
          end
        end
      end
    end
  end
end
