# frozen_string_literal: true

module V1
  module Entities
    class ConversationEntity < Blueprinter::Base
      identifier :id

      fields :status, :priority, :source, :created_at, :updated_at

      association :inbox, blueprint: InboxEntity
      association :assignee, blueprint: UserEntity
    end
  end
end
