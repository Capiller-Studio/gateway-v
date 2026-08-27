# frozen_string_literal: true

module V1
  module Resources
    class NotificationSettings < Grape::API
      resource :notification_settings do
        before do
          authenticate_user!
          check_subscription!
        end

        desc 'Get current user notification settings'
        get do
          setting = current_account.with_shard do
            NotificationSetting.find_or_create_by!(account: current_account, user: current_user)
          end

          success(data: V1::Entities::NotificationSettingEntity.render_as_hash(setting))
        end

        desc 'Update current user notification settings'
        params do
          optional :email_conversation_created, type: Boolean
          optional :email_conversation_assigned, type: Boolean
          optional :email_conversation_resolved, type: Boolean
          optional :email_sla_breached, type: Boolean
          optional :email_message_created, type: Boolean
          optional :email_conversation_mention, type: Boolean
          optional :email_team_assigned, type: Boolean

          optional :push_conversation_created, type: Boolean
          optional :push_conversation_assigned, type: Boolean
          optional :push_conversation_resolved, type: Boolean
          optional :push_sla_breached, type: Boolean
          optional :push_message_created, type: Boolean
          optional :push_conversation_mention, type: Boolean
          optional :push_team_assigned, type: Boolean
        end
        patch do
          setting = current_account.with_shard do
            s = NotificationSetting.find_or_create_by!(account: current_account, user: current_user)
            update_params = declared(params, include_missing: false)
            s.update!(update_params)
            s
          end

          success(data: V1::Entities::NotificationSettingEntity.render_as_hash(setting))
        end
      end
    end
  end
end
