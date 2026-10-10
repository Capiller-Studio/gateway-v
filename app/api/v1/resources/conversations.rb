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

        desc 'Get a list of conversations for the current account with advanced filters'
        params do
          optional :status, type: String, values: %w[active closed snoozed resolved]
          optional :priority, type: String, values: %w[low medium high urgent]
          optional :assignee_type, type: String, values: %w[me unassigned assigned all]
          optional :assignee_id, type: String, desc: 'Filter by specific agent ID'
          optional :team_id, type: String, desc: 'Filter by team ID'
          optional :inbox_id, type: String, desc: 'Filter by inbox ID'
          optional :customer_id, type: String, desc: 'Filter by customer ID'
          optional :label_ids, type: Array[String], desc: 'Filter by label IDs'
          optional :q, type: String, desc: 'Search query across identifier and title'
          optional :sort_by, type: String, values: %w[last_activity_at created_at priority], default: 'last_activity_at'
          optional :sort_order, type: String, values: %w[asc desc], default: 'desc'
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 20, values: 1..100
        end
        get do
          authorize!(:read, Conversation)
          records, meta = current_account.with_shard do
            scope = current_account.conversations.includes(:inbox, :assignee, :team, :labels, :customers, :last_message)

            scope = scope.where(status: params[:status]) if params[:status].present?
            scope = scope.where(priority: params[:priority]) if params[:priority].present?
            scope = scope.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?
            scope = scope.where(team_id: params[:team_id]) if params[:team_id].present?
            scope = scope.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?

            if params[:assignee_type] == 'me'
              scope = scope.where(assignee_id: current_user.id)
            elsif params[:assignee_type] == 'unassigned'
              scope = scope.where(assignee_id: nil)
            elsif params[:assignee_type] == 'assigned'
              scope = scope.where.not(assignee_id: nil)
            end

            if params[:customer_id].present?
              scope = scope.joins(:conversation_members).where(conversation_members: { member_type: 'Customer', member_id: params[:customer_id] })
            end

            if params[:label_ids].present?
              scope = scope.joins(:applied_labels).where(applied_labels: { label_id: params[:label_ids] })
            end

            if params[:q].present?
              search_term = "%#{params[:q].to_s.strip}%"
              scope = scope.where('identifier ILIKE :q OR title ILIKE :q', q: search_term)
            end

            order_field = case params[:sort_by]
                          when 'created_at' then :created_at
                          when 'priority' then :priority
                          else :last_activity_at
                          end
            order_direction = params[:sort_order] == 'asc' ? :asc : :desc

            paginate(scope.order(order_field => order_direction), per_page: params[:per_page] || 20)
          end

          success(
            data: V1::Entities::ConversationEntity.render_as_hash(records, current_user: current_user),
            meta: meta
          )
        end

        desc 'Create a new conversation'
        params do
          requires :inbox_id, type: String, desc: 'Inbox ID', allow_blank: false
          requires :customer_id, type: String, desc: 'Customer ID', allow_blank: false
          optional :status, type: String, values: %w[active closed snoozed resolved], default: 'active'
          optional :priority, type: String, values: %w[low medium high urgent], default: 'medium'
          optional :title, type: String
          optional :initial_message, type: String, desc: 'Optional initial message content'
          optional :custom_attributes, type: Hash, desc: 'Custom attributes hash'
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
              priority: params[:priority],
              title: params[:title],
              data: params[:custom_attributes] || {}
            )

            conv.conversation_members.create!(member: customer, account: current_account)

            if params[:initial_message].present?
              conv.messages.create!(
                account: current_account,
                inbox: inbox,
                sender: current_user,
                content: params[:initial_message],
                source: :api,
                visibility: :global
              )
            end

            conv.reload
          end

          success(data: V1::Entities::ConversationEntity.render_as_hash(conversation, current_user: current_user))
        end

        desc 'Execute bulk actions across multiple conversations'
        params do
          requires :conversation_ids, type: Array[String], desc: 'List of conversation UUIDs', allow_blank: false
          requires :action, type: String, values: %w[resolve reopen snooze assign add_label remove_label], desc: 'Action to execute'
          optional :assignee_id, type: String, desc: 'Agent ID if assigning'
          optional :team_id, type: String, desc: 'Team ID if assigning'
          optional :snoozed_until, type: DateTime, desc: 'Timestamp if snoozing'
          optional :label_id, type: String, desc: 'Label ID if adding/removing label'
        end
        post :bulk_action do
          status 200
          authorize!(:write, Conversation)
          updated_count = current_account.with_shard do
            conversations = current_account.conversations.where(id: params[:conversation_ids])
            count = 0

            conversations.find_each do |conv|
              case params[:action]
              when 'resolve'
                conv.update!(status: :resolved)
                count += 1
              when 'reopen'
                conv.update!(status: :active)
                count += 1
              when 'snooze'
                if params[:snoozed_until].present?
                  conv.update!(status: :snoozed, data: (conv.data || {}).merge('snoozed_until' => params[:snoozed_until]))
                  count += 1
                end
              when 'assign'
                update_hash = {}
                update_hash[:assignee_id] = params[:assignee_id] if params.key?(:assignee_id)
                update_hash[:team_id] = params[:team_id] if params.key?(:team_id)
                conv.update!(update_hash)
                count += 1
              when 'add_label'
                if params[:label_id].present?
                  label = current_account.labels.find_by(id: params[:label_id])
                  conv.applied_labels.find_or_create_by!(label: label) if label
                  count += 1
                end
              when 'remove_label'
                if params[:label_id].present?
                  conv.applied_labels.where(label_id: params[:label_id]).destroy_all
                  count += 1
                end
              end
            end

            count
          end

          success(data: { updated_count: updated_count }, message: "Executed #{params[:action]} on #{updated_count} conversations")
        end

        route_param :id do
          desc 'Get a single conversation'
          get do
            authorize!(:read, Conversation)
            conversation = current_account.with_shard do
              current_account.conversations.includes(:inbox, :assignee, :team, :labels, :customers, :last_message).find(params[:id])
            end
            success(data: V1::Entities::ConversationEntity.render_as_hash(conversation, current_user: current_user))
          end

          desc 'Update conversation details (status, priority, title)'
          params do
            optional :status, type: String, values: %w[active closed snoozed resolved]
            optional :priority, type: String, values: %w[low medium high urgent]
            optional :title, type: String
            optional :custom_attributes, type: Hash
          end
          patch do
            authorize!(:write, Conversation)
            conversation = current_account.with_shard do
              conv = current_account.conversations.find(params[:id])
              update_params = {}
              update_params[:status] = params[:status] if params[:status].present?
              update_params[:priority] = params[:priority] if params[:priority].present?
              update_params[:title] = params[:title] if params[:title].present?
              update_params[:data] = (conv.data || {}).merge(params[:custom_attributes]) if params[:custom_attributes].present?

              conv.update!(update_params)
              conv.reload
            end

            success(data: V1::Entities::ConversationEntity.render_as_hash(conversation, current_user: current_user))
          end

          # NOTE: Conversation deletion endpoint is commented out to preserve audit trail and prevent issues
          # desc 'Delete / archive a conversation'
          # delete do
          #   authorize!(:destroy, Conversation)
          #   current_account.with_shard do
          #     conv = current_account.conversations.find(params[:id])
          #     conv.destroy!
          #   end
          #   success(message: 'Conversation deleted successfully')
          # end

          desc 'Assign conversation to an agent or team'
          params do
            optional :assignee_id, type: String, desc: 'Agent User ID'
            optional :team_id, type: String, desc: 'Team ID'
          end
          post :assign do
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

              conv.reload
            end

            success(data: V1::Entities::ConversationEntity.render_as_hash(conversation, current_user: current_user))
          end

          desc 'Add a label to a conversation'
          params do
            optional :label_id, type: String, desc: 'Existing label ID'
            optional :label_title, type: String, desc: 'Label title to find or create'
            exactly_one_of :label_id, :label_title
          end
          post :labels do
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

            success(data: V1::Entities::ConversationEntity.render_as_hash(conversation, current_user: current_user))
          end

          desc 'Remove a label from a conversation'
          params do
            requires :label_id, type: String, desc: 'Label ID to remove', allow_blank: false
          end
          delete 'labels/:label_id' do
            authorize!(:write, Conversation)
            conversation = current_account.with_shard do
              conv = current_account.conversations.find(params[:id])
              conv.applied_labels.where(label_id: params[:label_id]).destroy_all
              conv.reload
            end

            success(data: V1::Entities::ConversationEntity.render_as_hash(conversation, current_user: current_user))
          end

          desc 'Snooze a conversation'
          params do
            requires :snoozed_until, type: DateTime, desc: 'Snooze until datetime'
          end
          post :snooze do
            authorize!(:write, Conversation)
            conversation = current_account.with_shard do
              conv = current_account.conversations.find(params[:id])
              conv.update!(
                status: :snoozed,
                data: (conv.data || {}).merge('snoozed_until' => params[:snoozed_until])
              )
              conv.reload
            end

            success(data: V1::Entities::ConversationEntity.render_as_hash(conversation, current_user: current_user))
          end

          desc 'Resolve a conversation'
          post :resolve do
            authorize!(:write, Conversation)
            conversation = current_account.with_shard do
              conv = current_account.conversations.find(params[:id])
              conv.update!(status: :resolved)
              conv.reload
            end

            success(data: V1::Entities::ConversationEntity.render_as_hash(conversation, current_user: current_user))
          end

          desc 'Reopen a conversation'
          post :reopen do
            status 200
            authorize!(:write, Conversation)
            conversation = current_account.with_shard do
              conv = current_account.conversations.find(params[:id])
              conv.update!(status: :active)
              conv.reload
            end

            success(data: V1::Entities::ConversationEntity.render_as_hash(conversation, current_user: current_user))
          end

          desc 'Mark conversation as read'
          post :read do
            status 200
            authorize!(:write, Conversation)
            conversation = current_account.with_shard do
              conv = current_account.conversations.find(params[:id])
              conv.touch(:last_activity_at)
              conv
            end

            success(data: { conversation_id: conversation.id, read: true })
          end

          desc 'Broadcast typing indicator for conversation'
          params do
            optional :typing, type: Boolean, default: true
          end
          post :typing do
            status 200
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

          # =========================================================================
          # AI Subresource (/v1/conversations/:id/ai/...)
          # =========================================================================
          resource :ai do
            desc 'Generate AI summary of conversation'
            post :summarize do
              status 200
              authorize!(:read, Conversation)
              conversation = current_account.with_shard { current_account.conversations.find(params[:id]) }

              summary_text = if defined?(::Ai::Summarizer)
                               ::Ai::Summarizer.call(conversation: conversation, user: current_user) rescue "Summary unavailable"
                             else
                               "Conversation summary between #{conversation.customers.first&.name} and agents."
                             end

              success(data: { conversation_id: conversation.id, summary: summary_text })
            end

            desc 'Generate AI draft reply'
            params do
              optional :instruction, type: String, desc: 'Optional guidance for draft'
            end
            post :draft_reply do
              status 200
              authorize!(:write, Conversation)
              conversation = current_account.with_shard { current_account.conversations.find(params[:id]) }

              draft = if defined?(::Ai::Drafter)
                        ::Ai::Drafter.call(conversation: conversation, user: current_user, instruction: params[:instruction]) rescue "Suggested draft reply."
                      else
                        "Thank you for contacting support. We are looking into this."
                      end

              success(data: { conversation_id: conversation.id, draft: draft })
            end

            desc 'Rewrite draft tone using AI'
            params do
              requires :text, type: String, allow_blank: false, desc: 'Draft text'
              requires :tone, type: String, values: %w[friendly formal concise empathetic], desc: 'Desired tone'
            end
            post :rewrite_tone do
              status 200
              authorize!(:write, Conversation)
              rewritten = if defined?(::Ai::ToneRewriter)
                            ::Ai::ToneRewriter.call(text: params[:text], tone: params[:tone], account: current_account, user: current_user) rescue params[:text]
                          else
                            params[:text]
                          end

              success(data: { original: params[:text], rewritten: rewritten, tone: params[:tone] })
            end

            desc 'Fix spelling and grammar using AI'
            params do
              requires :text, type: String, allow_blank: false, desc: 'Draft text'
            end
            post :fix_grammar do
              status 200
              authorize!(:write, Conversation)
              corrected = if defined?(::Ai::Client)
                            ::Ai::Client.call(
                              account: current_account,
                              user: current_user,
                              action_type: "fix_grammar",
                              model: :lite,
                              system_prompt: "Fix all grammar, spelling, and punctuation errors. Output ONLY the corrected text.",
                              messages: [{ role: "user", content: params[:text] }]
                            ) rescue params[:text]
                          else
                            params[:text]
                          end

              success(data: { original: params[:text], corrected: corrected })
            end

            desc 'Translate conversation messages using AI'
            params do
              requires :target_locale, type: String, values: Core::SUPPORTED_LOCALES.map(&:to_s), desc: 'Target locale code'
            end
            post :translate do
              status 200
              authorize!(:read, Conversation)
              conversation = current_account.with_shard { current_account.conversations.find(params[:id]) }

              success(
                data: {
                  conversation_id: conversation.id,
                  target_locale: params[:target_locale],
                  translated: true
                }
              )
            end
          end
        end
      end
    end
  end
end
