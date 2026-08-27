# frozen_string_literal: true

module V1
  module Entities
    class AgentEntity < Blueprinter::Base
      identifier :id

      fields :availability, :availability_changed_at, :created_at

      field :role do |account_user|
        account_user.owner? ? 'owner' : (account_user.roles.first&.name || 'agent')
      end

      association :user, blueprint: V1::Entities::UserEntity
    end
  end
end
