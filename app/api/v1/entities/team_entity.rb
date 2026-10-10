# frozen_string_literal: true

module V1
  module Entities
    class TeamEntity < Blueprinter::Base
      identifier :id

      fields :name, :identifier, :description, :status, :auto_assign, :created_at

      field :member_count do |team|
        team.team_users.count
      end

      field :member_ids do |team|
        team.team_users.pluck(:user_id).map(&:to_s)
      end
    end
  end
end
