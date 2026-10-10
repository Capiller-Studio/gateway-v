# frozen_string_literal: true

module V1
  module Entities
    class InboxEntity < Blueprinter::Base
      identifier :id

      fields :name, :display_name, :channel_type, :channel_id, :default_locale, :timezone, :status,
             :auto_assign, :csat_survey_enabled, :configurations, :created_at, :updated_at

      field :member_ids do |inbox|
        inbox.assigned_user_ids
      end

      field :team_ids do |inbox|
        inbox.assigned_team_ids
      end
    end
  end
end
