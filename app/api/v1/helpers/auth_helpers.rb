# frozen_string_literal: true

module V1
  module Helpers
    module AuthHelpers
      def authenticate_user!
        error!({ success: false, errors: [{ code: "unauthorized", message: I18n.t("gateway.errors.unauthorized", default: "Authentication required") }] }, 401) unless current_user && current_account
      end

      def authenticate_mobile_app!
        expected_secret = Rails.application.credentials.dig(Rails.env.to_sym, :mobile_app_secret) || 
                          Rails.application.credentials.dig(:mobile_app_secret) || 
                          ENV['MOBILE_APP_SECRET'] || "dev_mobile_secret_123"
                          
        provided_secret = headers['X-Mobile-App-Secret']
        
        unless provided_secret.present? && ActiveSupport::SecurityUtils.secure_compare(expected_secret.to_s, provided_secret)
          error!({ success: false, errors: [{ code: "forbidden", message: I18n.t("gateway.errors.mobile_app_restricted", default: "Registration is restricted to the internal mobile app.") }] }, 403)
        end
      end

      def check_api_feature!
        return if auth_type == :jwt

        unless current_account&.feature_enabled?("channels.api") || current_account&.feature_enabled?("api_access")
          error!({ success: false, errors: [{ code: "forbidden", message: I18n.t("gateway.errors.feature_disabled", default: "API Channel feature is not enabled for your account.") }] }, 403)
        end
      end

      def check_subscription!
        unless current_account&.subscribed?
          error!({ success: false, errors: [{ code: "payment_required", message: I18n.t("gateway.errors.subscription_inactive", default: "Your account subscription is inactive or limit reached. Payment is required.") }] }, 402)
        end
      end

      def auth_type
        resolve_auth! unless defined?(@auth_type) && !@auth_type.nil?
        @auth_type
      end

      def current_user
        resolve_auth! unless defined?(@current_user) && !@current_user.nil?
        @current_user
      end

      def current_account
        resolve_auth! unless defined?(@current_account) && !@current_account.nil?
        @current_account
      end

      def current_access_token
        resolve_auth! unless defined?(@current_access_token) && !@current_access_token.nil?
        @current_access_token
      end

      def current_account_user
        @current_account_user ||= current_user&.account_users&.find_by(account: current_account)
      end

      private

      def resolve_auth!
        @current_user = nil
        @current_account = nil
        @current_access_token = nil
        @auth_type = nil

        if (token = headers['Authorization']&.split(' ')&.last)
          payload = JwtService.decode(token)
          if payload && (user = User.find_by(id: payload[:user_id]))
            @current_user = user
            @auth_type = :jwt
            account_id = headers['X-Account-Id'].presence || payload[:account_id].presence
            @current_account = if account_id
              user.accounts.find_by(id: account_id)
            else
              user.accounts.first
            end
            return
          end
        end

        if (key = headers['X-Api-Key'])
          access_token = AccessToken.where(token_type: :api_key).find_by(token: key)
          if access_token && (access_token.valid_till.nil? || access_token.valid_till >= Time.current)
            @current_access_token = access_token
            @auth_type = :api_key
            if access_token.owner.is_a?(Account)
              @current_account = access_token.owner
              @current_user = @current_account.account_users.find_by(owner: true)&.user || @current_account.users.first
            elsif access_token.owner.is_a?(User)
              @current_user = access_token.owner
              account_id = headers['X-Account-Id']
              @current_account = if account_id
                @current_user.accounts.find_by(id: account_id)
              else
                @current_user.accounts.first
              end
            end
            return
          end
        end
      end
    end
  end
end
