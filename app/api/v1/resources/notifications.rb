# frozen_string_literal: true

module V1
  module Resources
    class Notifications < Grape::API
      resource :notifications do
        before do
          authenticate_user!
          check_subscription!
        end

        desc 'Get a paginated list of notifications for current user'
        params do
          optional :unread, type: Boolean, desc: 'Filter by unread notifications only'
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 20, values: 1..100
        end
        get do
          records, meta = current_account.with_shard do
            scope = Notification.where(account_id: current_account.id, user_id: current_user.id).recent
            scope = scope.unread if params[:unread] == true
            paginate(scope, per_page: params[:per_page] || 20)
          end

          success(
            data: V1::Entities::NotificationEntity.render_as_hash(records),
            meta: meta
          )
        end

        desc 'Get unread notification count for badge'
        get :unread_count do
          count = current_account.with_shard do
            Notification.where(account_id: current_account.id, user_id: current_user.id).unread.count
          end

          success(data: { unread_count: count })
        end

        desc 'Mark a single notification as read'
        params do
          requires :id, type: String, desc: 'Notification ID', allow_blank: false
        end
        patch ':id/read' do
          notification = current_account.with_shard do
            notif = Notification.where(account_id: current_account.id, user_id: current_user.id).find(params[:id])
            notif.update!(read_at: Time.current) if notif.read_at.nil?
            notif
          end

          success(data: V1::Entities::NotificationEntity.render_as_hash(notification))
        end

        desc 'Mark all notifications as read for current user'
        post :read_all do
          count = current_account.with_shard do
            Notification.where(account_id: current_account.id, user_id: current_user.id).unread.update_all(read_at: Time.current)
          end

          success(data: { success: true, updated_count: count })
        end
      end
    end
  end
end
