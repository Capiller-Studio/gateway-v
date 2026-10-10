# frozen_string_literal: true

module V1
  module Entities
    class WebhookEntity < Blueprinter::Base
      identifier :id

      fields :name, :status, :created_at, :updated_at

      field :url do |integration|
        integration.webhook_url
      end

      field :events do |integration|
        integration.subscribed_events
      end

      field :inbox_ids do |integration|
        integration.subscribed_inboxes
      end
    end
  end
end
