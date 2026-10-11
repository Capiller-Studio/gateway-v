# frozen_string_literal: true

module V1
  module Resources
    class Searches < Grape::API
      resource :search do
        before do
          authenticate_user!
          check_subscription!
        end

        desc 'Search across conversations and messages'
        params do
          requires :q, type: String, allow_blank: false, desc: 'Search query'
          optional :type, type: String, values: %w[conversations messages], desc: 'Filter search by resource type'
          optional :inbox_id, type: String
          optional :status, type: String
          optional :priority, type: String
          optional :assignee_id, type: String
          optional :team_id, type: String
          optional :date_from, type: String
          optional :date_to, type: String
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 20, values: 1..50
        end
        get do
          query = params[:q].to_s.strip
          filters = {
            inbox_id: params[:inbox_id].presence,
            status: params[:status].presence,
            priority: params[:priority].presence,
            assignee_id: params[:assignee_id].presence,
            team_id: params[:team_id].presence,
            date_from: params[:date_from].presence,
            date_to: params[:date_to].presence
          }.compact

          begin
            service = Search::SearchService.new(
              query: query,
              account_id: current_account.id,
              filters: filters,
              page: params[:page],
              per_page: params[:per_page],
              type: params[:type]
            )

            results = service.call
            conversations = results[:conversations].to_a
            messages = results[:messages].to_a
          rescue StandardError => e
            Rails.logger.warn("[Search] Service call failed: #{e.message}")
            conversations = []
            messages = []
          end

          # Fallback to SQL search if Elasticsearch index is unpopulated or returned empty
          if conversations.blank? && (params[:type].blank? || params[:type] == 'conversations')
            conversations = current_account.with_shard do
              rel = current_account.conversations.where('identifier ILIKE :q OR title ILIKE :q', q: "%#{query}%")
              rel = rel.where(inbox_id: filters[:inbox_id]) if filters[:inbox_id].present?
              rel = rel.where(status: filters[:status]) if filters[:status].present?
              rel.limit(params[:per_page]).offset((params[:page] - 1) * params[:per_page]).to_a
            end
          end

          if messages.blank? && (params[:type].blank? || params[:type] == 'messages')
            messages = current_account.with_shard do
              rel = current_account.messages.where('content ILIKE :q', q: "%#{query}%")
              rel = rel.where(inbox_id: filters[:inbox_id]) if filters[:inbox_id].present?
              rel.limit(params[:per_page]).offset((params[:page] - 1) * params[:per_page]).to_a
            end
          end

          success(
            data: {
              conversations: V1::Entities::ConversationEntity.render_as_hash(conversations),
              messages: V1::Entities::MessageEntity.render_as_hash(messages)
            },
            meta: {
              query: query,
              page: params[:page],
              per_page: params[:per_page]
            }
          )
        end

        desc 'Get search suggestions for typeahead'
        params do
          requires :q, type: String, allow_blank: false, desc: 'Query string'
        end
        get :suggestions do
          query = params[:q].to_s.strip
          begin
            service = Search::SearchService.new(
              query: query,
              account_id: current_account.id
            )

            results = service.suggestions
            conversations = results[:conversations].to_a
            messages = results[:messages].to_a
          rescue StandardError => e
            Rails.logger.warn("[Search] Suggestions failed: #{e.message}")
            conversations = []
            messages = []
          end

          if conversations.blank?
            conversations = current_account.with_shard do
              current_account.conversations.where('identifier ILIKE :q OR title ILIKE :q', q: "%#{query}%").limit(5).to_a
            end
          end

          if messages.blank?
            messages = current_account.with_shard do
              current_account.messages.where('content ILIKE :q', q: "%#{query}%").limit(5).to_a
            end
          end

          conv_suggestions = conversations.map do |conv|
            customer = conv.customers.first
            {
              id: conv.id,
              identifier: conv.identifier,
              title: conv.title,
              status: conv.status,
              priority: conv.priority,
              customer_name: customer&.name || customer&.display_name,
              customer_email: customer&.email,
              inbox_name: conv.inbox&.name
            }
          end

          msg_suggestions = messages.map do |msg|
            {
              id: msg.id,
              content: msg.content.to_s.truncate(120),
              sender_name: msg.sender&.name || msg.sender&.display_name,
              sender_type: msg.sender_type,
              conversation_id: msg.conversation_id,
              created_at: msg.created_at
            }
          end

          success(
            data: {
              conversations: conv_suggestions,
              messages: msg_suggestions
            }
          )
        end
      end
    end
  end
end
