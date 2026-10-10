# frozen_string_literal: true

module V1
  module Entities
    class ConversationEntity < Blueprinter::Base
      identifier :id

      fields :identifier, :title, :status, :priority, :source, :last_activity_at, :created_at, :updated_at

      association :inbox, blueprint: InboxEntity
      association :assignee, blueprint: UserEntity
      association :team, blueprint: TeamEntity
      association :labels, blueprint: LabelEntity

      association :customer, blueprint: CustomerEntity do |conversation|
        conversation.customers.first
      end

      association :last_message, blueprint: MessageEntity

      field :custom_attributes do |conversation|
        conversation.data || {}
      end

      field :unread_count do |_conversation, _options|
        0
      end
    end
  end
end
