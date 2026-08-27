# frozen_string_literal: true

module V1
  module Entities
    class DeviceEntity < Blueprinter::Base
      identifier :id

      fields :name, :subscription_type, :created_at

      field :token do |sub|
        sub.push_token
      end

      field :platform do |sub|
        sub.data['platform'] || sub.subscription_type
      end
    end
  end
end
