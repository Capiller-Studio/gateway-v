# frozen_string_literal: true

module V1
  module Helpers
    module SdkAuthHelpers
      def authenticate_sdk_channel!
        app_id = headers["X-Deskbolic-App-Id"].to_s.strip
        if app_id.blank? || !app_id.start_with?(Channel::MobileWidget::IDENTIFIER_PREFIX)
          error!({ success: false, errors: [{ code: "invalid_app_id", message: "Missing or invalid X-Deskbolic-App-Id header" }] }, 401)
        end

        routing = Rails.cache.fetch("sdk_routing:#{app_id}", expires_in: 5.minutes) do
          GlobalRouting.find_by(route_type: "mobile_widget", route_value: app_id)&.slice(:account_id)
        end

        unless routing && routing[:account_id]
          error!({ success: false, errors: [{ code: "channel_not_found", message: "Mobile Widget channel not found" }] }, 401)
        end

        @current_account = Account.find_by(id: routing[:account_id])
        unless @current_account&.active?
          error!({ success: false, errors: [{ code: "account_inactive", message: "Account is inactive or suspended" }] }, 401)
        end

        unless @current_account.subscribed?
          error!({ success: false, errors: [{ code: "payment_required", message: "Account subscription is inactive or expired" }] }, 402)
        end

        unless @current_account.feature_enabled?("channels.mobile_widget")
          error!({ success: false, errors: [{ code: "feature_disabled", message: "Mobile Widget channel is not enabled for your subscription plan" }] }, 403)
        end
      end

      def with_sdk_shard(&block)
        authenticate_sdk_channel! unless @current_account
        @current_account.with_shard(&block)
      end

      def current_account
        @current_account
      end

      def current_channel
        @current_channel ||= with_sdk_shard do
          Channel::MobileWidget.includes(:primary_inbox, :translations)
                               .find_by!(identifier: headers["X-Deskbolic-App-Id"], account: @current_account)
        end
      end

      def current_inbox
        @current_inbox ||= current_channel.primary_inbox
      end

      def authenticate_sdk_customer!
        authenticate_sdk_channel! unless @current_account

        token = headers["X-Customer-Session-Token"].presence ||
                headers["Authorization"]&.split(" ")&.last

        if token.blank?
          error!({ success: false, errors: [{ code: "session_token_required", message: "Session token required" }] }, 401)
        end

        payload = Channels::MobileWidgets::SessionToken.decode(token, channel: current_channel)
        unless payload && payload[:customer_id]
          error!({ success: false, errors: [{ code: "invalid_session_token", message: "Session token is invalid or expired" }] }, 401)
        end

        with_sdk_shard do
          @current_customer_inbox = current_inbox.customer_inboxes.includes(:customer).find_by(customer_id: payload[:customer_id])
          unless @current_customer_inbox
            error!({ success: false, errors: [{ code: "customer_not_found", message: "Customer inbox session not found" }] }, 401)
          end
          @current_customer = @current_customer_inbox.customer
        end
      end

      def current_customer
        @current_customer
      end

      def current_customer_inbox
        @current_customer_inbox
      end
    end
  end
end
