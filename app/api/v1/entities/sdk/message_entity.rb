# frozen_string_literal: true

module V1
  module Entities
    module Sdk
      class MessageEntity < Blueprinter::Base
        identifier :id

        fields :conversation_id, :content, :content_type, :status, :created_at, :edited_at

        field :deleted do |message|
          message.deleted?
        end

        field :client_message_id do |message|
          message.data["client_message_id"] rescue nil
        end

        association :sender, blueprint: SenderEntity
        association :attachments, blueprint: AttachmentEntity
      end
    end
  end
end
