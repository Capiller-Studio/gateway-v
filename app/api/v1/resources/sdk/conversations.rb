# frozen_string_literal: true

module V1
  module Resources
    module Sdk
      class Conversations < Grape::API
        resource :conversations do
          before do
            authenticate_sdk_customer!
          end

          desc 'List customer conversations'
          params do
            optional :page, type: Integer, default: 1
            optional :per_page, type: Integer, default: 20
          end
          get do
            relation = with_sdk_shard do
              current_customer.conversations
                              .where(inbox: current_inbox)
                              .order(last_activity_at: :desc, created_at: :desc)
            end

            paginated_conversations, meta = paginate(relation)

            success(
              data: V1::Entities::Sdk::ConversationEntity.render_as_hash(
                paginated_conversations,
                customer: current_customer
              ),
              meta: meta
            )
          end

          desc 'Create a new conversation with initial message'
          params do
            requires :content, type: String, allow_blank: false, desc: 'Initial message content'
            optional :title, type: String, desc: 'Optional conversation title'
            optional :attachment_ids, type: Array[String], default: [], desc: 'ActiveStorage blob signed IDs'
          end
          post do
            conversation = with_sdk_shard do
              ShardRecord.transaction do
                conv = current_account.conversations.create!(
                  inbox: current_inbox,
                  source: :mobile_widget,
                  title: params[:title],
                  locale: detect_locale,
                  status: :active
                )

                conv.conversation_members.create!(
                  member: current_customer,
                  account: current_account
                )

                # Attachments resolution
                resolved_attachments = []
                if params[:attachment_ids].present?
                  params[:attachment_ids].each do |signed_id|
                    blob = ActiveStorage::Blob.find_signed(signed_id) rescue nil
                    resolved_attachments << blob if blob
                  end
                end

                ::Channels::WebWidgets::MessageCreator.call(
                  account: current_account,
                  inbox: current_inbox,
                  conversation: conv,
                  sender: current_customer,
                  content: params[:content],
                  attachments: resolved_attachments
                )

                conv
              end
            end

            status 201
            success(
              data: V1::Entities::Sdk::ConversationEntity.render_as_hash(
                conversation,
                customer: current_customer
              )
            )
          end

          route_param :id do
            desc 'Get conversation details'
            get do
              conversation = with_sdk_shard do
                current_customer.conversations.where(inbox: current_inbox).find_by(id: params[:id])
              end

              unless conversation
                failure(errors: [{ code: "conversation_not_found", message: "Conversation not found" }], status: 404)
              end

              success(
                data: V1::Entities::Sdk::ConversationEntity.render_as_hash(
                  conversation,
                  customer: current_customer
                )
              )
            end

            desc 'Mark conversation messages as read'
            post :read do
              conversation = with_sdk_shard do
                current_customer.conversations.where(inbox: current_inbox).find_by(id: params[:id])
              end

              unless conversation
                failure(errors: [{ code: "conversation_not_found", message: "Conversation not found" }], status: 404)
              end

              with_sdk_shard do
                unread_msgs = conversation.messages.where.not(sender_type: "Customer").where.not(status: :read)
                unread_msgs.find_each(&:read!) if unread_msgs.exists?
                ::UnreadCounts::Reset.call(conversation, current_customer)
              end

              success(message: 'Conversation marked as read')
            end
          end
        end
      end
    end
  end
end
