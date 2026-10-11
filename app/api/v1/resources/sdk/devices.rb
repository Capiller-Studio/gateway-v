# frozen_string_literal: true

module V1
  module Resources
    module Sdk
      class Devices < Grape::API
        resource :devices do
          before do
            authenticate_sdk_customer!
          end

          desc 'Register or update device push token'
          params do
            requires :push_token, type: String, allow_blank: false, desc: 'APNs or FCM push token'
            requires :platform, type: String, values: %w[ios android], desc: 'Device operating system'
            optional :push_provider, type: String, values: %w[apns fcm], desc: 'Push delivery service'
            optional :device_identifier, type: String, desc: 'Stable install UUID'
            optional :device_model, type: String
            optional :os_version, type: String
            optional :app_version, type: String
            optional :sdk_version, type: String
            optional :locale, type: String
            optional :timezone, type: String
          end
          post do
            provider = params[:push_provider].presence || (params[:platform] == 'ios' ? 'apns' : 'fcm')

            device = with_sdk_shard do
              dev = current_inbox.customer_devices.where(push_token: params[:push_token]).first ||
                    current_inbox.customer_devices.new(push_token: params[:push_token])

              dev.account = current_account
              dev.customer = current_customer
              dev.customer_inbox = current_customer_inbox
              dev.platform = params[:platform]
              dev.push_provider = provider
              dev.status = :active
              dev.device_identifier = params[:device_identifier] if params[:device_identifier].present?
              dev.device_model = params[:device_model] if params[:device_model].present?
              dev.os_version = params[:os_version] if params[:os_version].present?
              dev.app_version = params[:app_version] if params[:app_version].present?
              dev.sdk_version = params[:sdk_version] if params[:sdk_version].present?
              dev.locale = params[:locale].presence || detect_locale
              dev.timezone = params[:timezone] if params[:timezone].present?
              dev.last_seen_at = Time.current
              dev.save!
              dev
            end

            success(data: V1::Entities::Sdk::DeviceEntity.render_as_hash(device))
          end

          desc 'Unregister device push token'
          params do
            requires :token, type: String, allow_blank: false
          end
          delete ':token' do
            with_sdk_shard do
              current_inbox.customer_devices.where(push_token: params[:token]).destroy_all
            end

            success(message: 'Device push token unregistered successfully')
          end
        end
      end
    end
  end
end
