# frozen_string_literal: true

module V1
  module Entities
    class MessageEntity < Blueprinter::Base
      identifier :id

      fields :content, :message_type, :status, :source, :sender_type, :sender_id, :created_at
      
      association :sender, blueprint: ->(sender) {
        if sender.is_a?(User)
          UserEntity
        else
          CustomerEntity
        end
      }
    end
  end
end
