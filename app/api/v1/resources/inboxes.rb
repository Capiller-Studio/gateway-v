# frozen_string_literal: true

module V1
  module Resources
    class Inboxes < Grape::API
      resource :inboxes do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get a list of inboxes for the current account'
        params do
          optional :channel_type, type: String, values: %w[email web_widget mobile_widget contact_form facebook instagram whatsapp custom], desc: 'Filter by channel type'
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 50, values: 1..100
        end
        get do
          authorize!(:read, Inbox)
          records, meta = current_account.with_shard do
            scope = current_account.inboxes.order(created_at: :asc)
            if params[:channel_type].present?
              channel_map = {
                'email' => 'Channel::Email',
                'web_widget' => 'Channel::WebWidget',
                'mobile_widget' => 'Channel::MobileWidget',
                'contact_form' => 'Channel::ContactForm',
                'facebook' => 'Channel::FacebookPage',
                'instagram' => 'Channel::Instagram',
                'whatsapp' => 'Channel::Whatsapp',
                'custom' => 'Channel::Custom'
              }
              mapped_class = channel_map[params[:channel_type]] || "Channel::#{params[:channel_type].camelize}"
              scope = scope.where(channel_type: [params[:channel_type], mapped_class])
            end
            paginate(scope, per_page: params[:per_page] || 50)
          end

          success(
            data: V1::Entities::InboxEntity.render_as_hash(records),
            meta: meta
          )
        end

        # NOTE: Inbox creation is configured strictly via the dashboard channel setup wizards.
        # Direct POST /v1/inboxes endpoint is omitted.

        route_param :id do
          desc 'Get a single inbox'
          get do
            authorize!(:read, Inbox)
            inbox = current_account.with_shard { current_account.inboxes.find(params[:id]) }
            success(data: V1::Entities::InboxEntity.render_as_hash(inbox))
          end

          desc 'Update an existing inbox'
          params do
            optional :name, type: String, allow_blank: false
            optional :display_name, type: String
            optional :default_locale, type: String
            optional :timezone, type: String
            optional :auto_assign, type: Boolean
            optional :csat_survey_enabled, type: Boolean
            optional :reopen_window_seconds, type: Integer
            optional :member_ids, type: Array[String], desc: 'List of agent IDs to assign'
            optional :team_ids, type: Array[String], desc: 'List of team IDs to assign'
          end
          patch do
            authorize!(:write, Inbox)
            inbox = current_account.with_shard do
              inbox = current_account.inboxes.find(params[:id])
              update_attrs = {}
              update_attrs[:name] = params[:name] if params[:name].present?
              update_attrs[:display_name] = params[:display_name] if params[:display_name].present?
              update_attrs[:default_locale] = params[:default_locale] if params[:default_locale].present?
              update_attrs[:timezone] = params[:timezone] if params[:timezone].present?
              update_attrs[:auto_assign] = params[:auto_assign] unless params[:auto_assign].nil?
              update_attrs[:csat_survey_enabled] = params[:csat_survey_enabled] unless params[:csat_survey_enabled].nil?
              if params[:reopen_window_seconds].present?
                inbox.configurations = (inbox.configurations || {}).merge('reopen_window_seconds' => params[:reopen_window_seconds])
              end

              inbox.update!(update_attrs) if update_attrs.any?
              inbox.assign_users(params[:member_ids]) if params[:member_ids].present?
              inbox.assign_teams(params[:team_ids]) if params[:team_ids].present?
              inbox
            end

            success(
              data: V1::Entities::InboxEntity.render_as_hash(inbox),
              message: 'Inbox updated successfully'
            )
          end

          desc 'Delete an inbox'
          delete do
            authorize!(:destroy, Inbox)
            current_account.with_shard do
              inbox = current_account.inboxes.find(params[:id])
              inbox.destroy!
            end

            success(message: 'Inbox deleted successfully')
          end

          # Inbox Members Subresource
          resource :members do
            desc 'Get assigned agents for this inbox'
            get do
              authorize!(:read, Inbox)
              members = current_account.with_shard do
                inbox = current_account.inboxes.find(params[:id])
                inbox.collaborator_users.to_a
              end

              success(data: V1::Entities::UserEntity.render_as_hash(members))
            end

            desc 'Assign agents to this inbox'
            params do
              requires :user_ids, type: Array[String], allow_blank: false, desc: 'Array of user IDs to add'
            end
            post do
              authorize!(:write, Inbox)
              inbox = current_account.with_shard do
                inbox = current_account.inboxes.find(params[:id])
                combined_ids = (inbox.assigned_user_ids + params[:user_ids]).uniq
                inbox.assign_users(combined_ids)
                inbox
              end

              status 200
              success(
                data: V1::Entities::InboxEntity.render_as_hash(inbox),
                message: 'Members assigned successfully'
              )
            end

            desc 'Remove an agent from this inbox'
            delete ':user_id' do
              authorize!(:write, Inbox)
              current_account.with_shard do
                inbox = current_account.inboxes.find(params[:id])
                inbox.inbox_users.where(user_id: params[:user_id]).destroy_all
              end

              success(message: 'Member removed from inbox successfully')
            end
          end
        end
      end
    end
  end
end
