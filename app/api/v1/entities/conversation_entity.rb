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
    end
  end
end
