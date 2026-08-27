# frozen_string_literal: true

module V1
  module Entities
    class NotificationEntity < Blueprinter::Base
      identifier :id

      fields :event,
             :read_at,
             :resource_type,
             :resource_id,
             :created_at,
             :updated_at

      field :read do |notification, _options|
        notification.read_at.present?
      end
    end
  end
end
