# frozen_string_literal: true

module V1
  module Entities
    class NotificationSettingEntity < Blueprinter::Base
      identifier :id

      fields :email_conversation_created,
             :email_conversation_assigned,
             :email_conversation_resolved,
             :email_sla_breached,
             :email_message_created,
             :email_conversation_mention,
             :email_team_assigned,
             :push_conversation_created,
             :push_conversation_assigned,
             :push_conversation_resolved,
             :push_sla_breached,
             :push_message_created,
             :push_conversation_mention,
             :push_team_assigned,
             :created_at,
             :updated_at
    end
  end
end
