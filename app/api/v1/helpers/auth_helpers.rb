# frozen_string_literal: true

module V1
  module Helpers
    module AuthHelpers
      def authenticate_user!
        error!({ errors: [{ code: "unauthorized", message: "Authentication required" }] }, 401) unless current_user
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
