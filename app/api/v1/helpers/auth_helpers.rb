# frozen_string_literal: true

module V1
  module Helpers
    module AuthHelpers
      def authenticate_user!
        error!({ errors: [{ code: "unauthorized", message: I18n.t("gateway.errors.unauthorized", default: "Authentication required") }] }, 401) unless current_user
      end

      def authenticate_mobile_app!
        expected_secret = Rails.application.credentials.dig(Rails.env.to_sym, :mobile_app_secret) || 
                          Rails.application.credentials.dig(:mobile_app_secret) || 
                          ENV['MOBILE_APP_SECRET'] || "dev_mobile_secret_123"
                          
        provided_secret = headers['X-Mobile-App-Secret']
        
        unless provided_secret.present? && ActiveSupport::SecurityUtils.secure_compare(expected_secret.to_s, provided_secret)
          error!({ errors: [{ code: "forbidden", message: I18n.t("gateway.errors.mobile_app_restricted", default: "Registration is restricted to the internal mobile app.") }] }, 403)
        end
      end

      def check_api_feature!
        unless current_account&.has_feature?("channels.api")
          error!({ errors: [{ code: "forbidden", message: I18n.t("gateway.errors.feature_disabled", default: "API Channel feature is not enabled for your account.") }] }, 403)
        end
      end

      def check_subscription!
        unless current_account&.active_subscription?
          error!({ errors: [{ code: "payment_required", message: I18n.t("gateway.errors.subscription_inactive", default: "Your account subscription is inactive or limit reached. Payment is required.") }] }, 402)
        end
      end

      def current_user
        @current_user ||= authenticate_with_jwt || authenticate_with_api_key
      end

      def current_account
        @current_account ||= begin
          account_id = headers['X-Account-Id']
          if account_id
            current_user&.accounts&.find_by(id: account_id)
          else
            current_user&.accounts&.first
          end
        end
      end

      def current_account_user
        @current_account_user ||= current_user&.account_users&.find_by(account: current_account)
      end

      private

      def authenticate_with_jwt
        token = headers['Authorization']&.split(' ')&.last
        return nil unless token

        payload = JwtService.decode(token)
        return nil unless payload

        User.find_by(id: payload[:user_id])
      end

      def authenticate_with_api_key
        key = headers['X-Api-Key']
        return nil unless key

        access_token = AccessToken.find_by(token: key)
        return nil unless access_token
        return nil if access_token.valid_till && access_token.valid_till < Time.current

        access_token.owner
      end
    end
  end
end
