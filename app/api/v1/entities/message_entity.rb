# frozen_string_literal: true

module V1
  module Entities
    class MessageEntity < Blueprinter::Base
      identifier :id

      fields :content, :content_type, :status, :source, :visibility, :sender_type, :sender_id, :created_at

      field :private do |message|
        message.personal?
      end
      
      association :sender, blueprint: ->(sender) {
        if sender.is_a?(User)
          UserEntity
        else
          CustomerEntity
        end
      }

      association :attachments, blueprint: AttachmentEntity
    end
  end
end
