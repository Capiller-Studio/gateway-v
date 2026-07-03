# frozen_string_literal: true

module V1
  module Resources
    class Conversations < Grape::API
      resource :conversations do
        before do
          authenticate_user!
          check_api_feature!
          check_subscription!
        end

        desc 'Get a list of conversations for the current account'
        params do
          optional :status, type: String, values: %w[open resolved snoozed pending]
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 20, values: 1..100
        end
        get do
          authorize!(:read, Conversation)
          conversations = current_account.conversations.includes(:inbox, :assignee)
          conversations = conversations.where(status: params[:status]) if params[:status].present?
          
          paginated = conversations.page(params[:page]).per(params[:per_page])

          success(
            data: V1::Entities::ConversationEntity.render_as_hash(paginated),
            meta: {
              current_page: paginated.current_page,
              total_pages: paginated.total_pages,
              total_count: paginated.total_count
            }
          )
        end

        desc 'Get a single conversation'
        params do
          requires :id, type: String, desc: 'Conversation ID', allow_blank: false
        end
        get ':id' do
          authorize!(:read, Conversation)
          conversation = current_account.conversations.find(params[:id])
          success(data: V1::Entities::ConversationEntity.render_as_hash(conversation))
        end

        desc 'Create a new conversation'
        params do
          requires :inbox_id, type: String, desc: 'Inbox ID', allow_blank: false
          requires :customer_id, type: String, desc: 'Customer ID', allow_blank: false
          optional :status, type: String, values: %w[open resolved snoozed pending], default: 'open'
          optional :priority, type: String, values: %w[low medium high urgent], default: 'medium'
        end
        post do
          authorize!(:write, Conversation)
          inbox = current_account.inboxes.find(params[:inbox_id])
          customer = current_account.customers.find(params[:customer_id])

          conversation = current_account.conversations.create!(
            inbox: inbox,
            source: :api,
            status: params[:status],
            priority: params[:priority]
          )

          conversation.conversation_members.create!(member: customer, account: current_account)

          success(data: V1::Entities::ConversationEntity.render_as_hash(conversation))
        end
      end
    end
  end
end
