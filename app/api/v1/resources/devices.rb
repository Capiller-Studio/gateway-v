# frozen_string_literal: true

module V1
  module Resources
    class Devices < Grape::API
      resource :devices do
        before do
          authenticate_user!
        end

        desc 'Register a device push token for notifications'
        params do
          requires :token, type: String, desc: 'Device Push Token (FCM or APNS)', allow_blank: false
          optional :platform, type: String, values: %w[fcm push apns ios android], default: 'fcm'
          optional :name, type: String, desc: 'Device Name'
        end
        post do
          subscription = current_account.with_shard do
            existing = current_user.notification_subscriptions.where("data->>'device_token' = ?", params[:token]).first
            sub = existing || current_user.notification_subscriptions.new
            sub.subscription_type = params[:platform] == 'push' ? :push : :fcm
            sub.name = params[:name] || "Mobile Device (#{params[:platform]})"
            sub.data = {
              'device_token' => params[:token],
              'platform' => params[:platform],
              'endpoint' => params[:token]
            }
            sub.save!
            sub
          end

          success(data: V1::Entities::DeviceEntity.render_as_hash(subscription))
        end

        desc 'Unregister a device push token'
        params do
          requires :token, type: String, desc: 'Device token to unregister', allow_blank: false
        end
        delete ':token' do
          current_account.with_shard do
            subs = current_user.notification_subscriptions.where(
              "data->>'device_token' = ? OR data->>'endpoint' = ?",
              params[:token],
              params[:token]
            )
            subs.destroy_all
          end

          success(message: 'Device unregistered successfully')
        end
      end
    end
  end
end
