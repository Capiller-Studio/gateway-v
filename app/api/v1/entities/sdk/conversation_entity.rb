# frozen_string_literal: true

module V1
  module Entities
    module Sdk
      class ConversationEntity < Blueprinter::Base
        identifier :id

        fields :identifier, :status, :created_at, :last_activity_at

        field :unread_count do |conversation, options|
          customer = options[:customer]
          if customer && conversation.account
            counts = UnreadCounts::Current.call(member: customer, account_id: conversation.account_id)
            counts.dig(:conversations, conversation.id.to_s).to_i rescue 0
          else
            0
          end
        end

        field :last_message do |conversation|
          last_msg = conversation.messages.global.order(created_at: :desc).first
          if last_msg
            MessageEntity.render_as_hash(last_msg)
          else
            nil
          end
        end

        association :assignee, blueprint: SenderEntity
      end
    end
  end
end
