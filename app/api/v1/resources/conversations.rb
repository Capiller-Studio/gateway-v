# frozen_string_literal: true

module V1
  module Resources
    class Conversations < Grape::API
      resource :conversations do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get a list of conversations for the current account'
        params do
          optional :status, type: String, values: %w[active closed snoozed resolved]
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 20, values: 1..100
        end
        get do
          authorize!(:read, Conversation)
          records, meta = current_account.with_shard do
            conversations = current_account.conversations.includes(:inbox, :assignee, :team, :labels).order(created_at: :desc)
            conversations = conversations.where(status: params[:status]) if params[:status].present?
            paginate(conversations, per_page: params[:per_page] || 20)
          end

          success(
            data: V1::Entities::ConversationEntity.render_as_hash(records),
            meta: meta
          )
        end

        desc 'Get a single conversation'
        params do
          requires :id, type: String, desc: 'Conversation ID', allow_blank: false
        end
        get ':id' do
          authorize!(:read, Conversation)
          conversation = current_account.with_shard do
            current_account.conversations.includes(:inbox, :assignee, :team, :labels).find(params[:id])
          end
          success(data: V1::Entities::ConversationEntity.render_as_hash(conversation))
        end

        desc 'Create a new conversation'
        params do
          requires :inbox_id, type: String, desc: 'Inbox ID', allow_blank: false
          requires :customer_id, type: String, desc: 'Customer ID', allow_blank: false
          optional :status, type: String, values: %w[active closed snoozed resolved], default: 'active'
          optional :priority, type: String, values: %w[low medium high urgent], default: 'medium'
        end
        post do
          authorize!(:write, Conversation)
          conversation = current_account.with_shard do
            inbox = current_account.inboxes.find(params[:inbox_id])
            customer = current_account.customers.find(params[:customer_id])

            conv = current_account.conversations.create!(
              inbox: inbox,
              source: :api,
              status: params[:status],
              priority: params[:priority]
            )

            conv.conversation_members.create!(member: customer, account: current_account)
            conv
          end

          success(data: V1::Entities::ConversationEntity.render_as_hash(conversation))
        end

        desc 'Update conversation details (status, priority, title)'
        params do
          requires :id, type: String, desc: 'Conversation ID', allow_blank: false
          optional :status, type: String, values: %w[active closed snoozed resolved]
          optional :priority, type: String, values: %w[low medium high urgent]
          optional :title, type: String
        end
        patch ':id' do
          authorize!(:write, Conversation)
          conversation = current_account.with_shard do
            conv = current_account.conversations.find(params[:id])
            update_params = {}
            update_params[:status] = params[:status] if params[:status].present?
            update_params[:priority] = params[:priority] if params[:priority].present?
            update_params[:title] = params[:title] if params[:title].present?

            conv.update!(update_params)
            conv
          end

          success(data: V1::Entities::ConversationEntity.render_as_hash(conversation))
        end

        desc 'Assign conversation to an agent or team'
        params do
          requires :id, type: String, desc: 'Conversation ID', allow_blank: false
          optional :assignee_id, type: String, desc: 'Agent User ID'
          optional :team_id, type: String, desc: 'Team ID'
        end
        post ':id/assign' do
          authorize!(:write, Conversation)
          conversation = current_account.with_shard do
            conv = current_account.conversations.find(params[:id])

            if params.key?(:assignee_id)
              if params[:assignee_id].present?
                assignee = current_account.users.find(params[:assignee_id])
                conv.update!(assignee: assignee)
                conv.conversation_members.find_or_create_by!(member: assignee, account: current_account)
              else
                conv.update!(assignee_id: nil)
              end
            end

            if params.key?(:team_id)
              if params[:team_id].present?
                team = current_account.teams.find(params[:team_id])
                conv.update!(team: team)
              else
                conv.update!(team_id: nil)
              end
            end

            conv
          end

          success(data: V1::Entities::ConversationEntity.render_as_hash(conversation))
        end

        desc 'Add a label to a conversation'
        params do
          requires :id, type: String, desc: 'Conversation ID', allow_blank: false
          optional :label_id, type: String, desc: 'Existing label ID'
          optional :label_title, type: String, desc: 'Label title to find or create'
          exactly_one_of :label_id, :label_title
        end
        post ':id/labels' do
          authorize!(:write, Conversation)
          conversation = current_account.with_shard do
            conv = current_account.conversations.find(params[:id])
            label = if params[:label_id].present?
                      current_account.labels.find(params[:label_id])
                    else
                      current_account.labels.find_or_create_by!(title: params[:label_title])
                    end

            conv.applied_labels.find_or_create_by!(label: label)
            conv.reload
          end

          success(data: V1::Entities::ConversationEntity.render_as_hash(conversation))
        end

        desc 'Remove a label from a conversation'
        params do
          requires :id, type: String, desc: 'Conversation ID', allow_blank: false
          requires :label_id, type: String, desc: 'Label ID to remove', allow_blank: false
        end
        delete ':id/labels/:label_id' do
          authorize!(:write, Conversation)
          conversation = current_account.with_shard do
            conv = current_account.conversations.find(params[:id])
            conv.applied_labels.where(label_id: params[:label_id]).destroy_all
            conv.reload
          end

          success(data: V1::Entities::ConversationEntity.render_as_hash(conversation))
        end

        desc 'Snooze a conversation'
        params do
          requires :id, type: String, desc: 'Conversation ID', allow_blank: false
          requires :snoozed_until, type: DateTime, desc: 'Snooze until datetime'
        end
        post ':id/snooze' do
          authorize!(:write, Conversation)
          conversation = current_account.with_shard do
            conv = current_account.conversations.find(params[:id])
            conv.update!(
              status: :snoozed,
              data: (conv.data || {}).merge('snoozed_until' => params[:snoozed_until])
            )
            conv
          end

          success(data: V1::Entities::ConversationEntity.render_as_hash(conversation))
        end

        desc 'Resolve a conversation'
        params do
          requires :id, type: String, desc: 'Conversation ID', allow_blank: false
        end
        post ':id/resolve' do
          authorize!(:write, Conversation)
          conversation = current_account.with_shard do
            conv = current_account.conversations.find(params[:id])
            conv.update!(status: :resolved)
            conv
          end

          success(data: V1::Entities::ConversationEntity.render_as_hash(conversation))
        end

        desc 'Broadcast typing indicator for conversation'
        params do
          requires :id, type: String, desc: 'Conversation ID', allow_blank: false
          optional :typing, type: Boolean, default: true
        end
        post ':id/typing' do
          authorize!(:write, Conversation)
          conversation = current_account.with_shard do
            current_account.conversations.find(params[:id])
          end

          begin
            ActionCable.server.broadcast(
              "conversation_#{conversation.id}",
              {
                event: 'agent_typing',
                user_id: current_user.id,
                user_name: current_user.display_name.presence || current_user.name,
                typing: params[:typing]
              }
            )
          rescue StandardError => e
            Rails.logger.warn("[ActionCable] Typing broadcast warning: #{e.message}")
          end

          success(data: { typing: params[:typing], conversation_id: conversation.id })
        end
      end
    end
  end
end
