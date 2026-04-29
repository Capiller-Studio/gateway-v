# frozen_string_literal: true

module V1
  module Helpers
    module AuthHelpers
      def authenticate_user!
        error!('401 Unauthorized', 401) unless current_user
      end

      def current_user
        @current_user ||= authenticate_with_jwt || authenticate_with_api_key
      end

      private

      def authenticate_with_jwt
        token = headers['Authorization']&.split(' ')&.last
        return nil unless token

        begin
          payload = JWT.decode(token, Rails.application.credentials.secret_key_base).first
          User.find(payload['user_id'])
        rescue JWT::DecodeError
          nil
        end
      end

      def authenticate_with_api_key
        key = headers['X-Api-Key']
        return nil unless key

        token = AccessToken.find_by(token: key)
        return nil if token.nil? || (token.valid_till && token.valid_till < Time.current)

        token.owner if token.owner_type == 'User'
      end
    end
  end
end
