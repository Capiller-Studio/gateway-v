# frozen_string_literal: true

module V1
  module Resources
    module Sdk
      class Unread < Grape::API
        resource :unread_count do
          before do
            authenticate_sdk_customer!
          end

          desc 'Get customer unread messages count'
          get do
            counts = ::UnreadCounts::Current.call(member: current_customer, account_id: current_account.id)
            inbox_count = counts.dig(:inboxes, current_inbox.id.to_s).to_i

            success(data: { unread_count: inbox_count })
          end
        end
      end
    end
  end
end
