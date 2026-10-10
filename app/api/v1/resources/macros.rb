# frozen_string_literal: true

module V1
  module Resources
    class Macros < Grape::API
      resource :macros do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get a list of macros accessible by current user'
        params do
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 50, values: 1..100
        end
        get do
          authorize!(:read, Macro)
          records, meta = current_account.with_shard do
            macros = Macro.visible_to(current_user, current_account).order(created_at: :desc)
            paginate(macros, per_page: params[:per_page] || 50)
          end

          success(
            data: V1::Entities::MacroEntity.render_as_hash(records),
            meta: meta
          )
        end

        desc 'Create a new macro'
        params do
          requires :name, type: String, allow_blank: false, desc: 'Macro title'
          optional :description, type: String, desc: 'Macro description'
          requires :actions, type: Array[JSON], allow_blank: false, desc: 'List of actions to execute'
          optional :visibility, type: String, values: %w[account_wide personal team], default: 'account_wide'
          optional :team_id, type: String, desc: 'Team ID if visibility is team'
          optional :status, type: String, values: %w[active inactive], default: 'active'
        end
        post do
          authorize!(:manage, Macro)
          macro = current_account.with_shard do
            scopeable = case params[:visibility]
                        when 'personal'
                          current_user
                        when 'team'
                          current_account.teams.find(params[:team_id])
                        end

            current_account.macros.create!(
              name: params[:name],
              description: params[:description],
              actions: params[:actions],
              visibility: params[:visibility],
              scopeable: scopeable,
              status: params[:status] || 'active'
            )
          end

          status 201
          success(
            data: V1::Entities::MacroEntity.render_as_hash(macro),
            message: 'Macro created successfully'
          )
        end

        route_param :id do
          desc 'Get a macro by ID'
          get do
            authorize!(:read, Macro)
            macro = current_account.with_shard do
              m = current_account.macros.find(params[:id])
              error!({ success: false, errors: [{ code: 'forbidden', message: 'You do not have access to this macro' }] }, 403) unless m.visible_to?(current_user)
              m
            end

            success(data: V1::Entities::MacroEntity.render_as_hash(macro))
          end

          desc 'Update a macro'
          params do
            optional :name, type: String, allow_blank: false
            optional :description, type: String
            optional :actions, type: Array[JSON]
            optional :status, type: String, values: %w[active inactive]
          end
          patch do
            authorize!(:manage, Macro)
            macro = current_account.with_shard do
              m = current_account.macros.find(params[:id])
              update_attrs = {}
              update_attrs[:name] = params[:name] if params[:name].present?
              update_attrs[:description] = params[:description] if params.key?(:description)
              update_attrs[:actions] = params[:actions] if params[:actions].present?
              update_attrs[:status] = params[:status] if params[:status].present?

              m.update!(update_attrs) if update_attrs.any?
              m
            end

            success(
              data: V1::Entities::MacroEntity.render_as_hash(macro),
              message: 'Macro updated successfully'
            )
          end

          desc 'Delete a macro'
          delete do
            authorize!(:manage, Macro)
            current_account.with_shard do
              m = current_account.macros.find(params[:id])
              m.destroy!
            end

            success(message: 'Macro deleted successfully')
          end

          desc 'Execute a macro against a conversation'
          params do
            requires :conversation_id, type: String, allow_blank: false, desc: 'Conversation ID'
          end
          post :execute do
            authorize!(:execute, Macro)
            result, conv = current_account.with_shard do
              macro = current_account.macros.find(params[:id])
              conversation = current_account.conversations.find(params[:conversation_id])

              res = ::Macros::Executor.call(
                macro: macro,
                conversation: conversation,
                actor: current_user
              )
              [res, conversation.reload]
            end

            status 200
            success(
              data: {
                status: result.status,
                results: result.results,
                succeeded_count: result.succeeded_count,
                failed_count: result.failed_results.size,
                conversation: V1::Entities::ConversationEntity.render_as_hash(conv)
              },
              message: "Macro executed with status: #{result.status}"
            )
          end
        end
      end
    end
  end
end
