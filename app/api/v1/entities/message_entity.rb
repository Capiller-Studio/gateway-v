# frozen_string_literal: true

module V1
  module Entities
    class MessageEntity < Blueprinter::Base
      identifier :id

      fields :conversation_id, :content, :content_type, :status, :source, :visibility, :sender_type, :sender_id, :created_at

      field :private do |message|
        message.personal?
      end

      field :reactions do |message|
        message.reactions.map do |r|
          {
            id: r.id,
            emoji: r.emoji,
            sender_id: r.sender_id,
            sender_type: r.sender_type
          }
        end rescue []
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
