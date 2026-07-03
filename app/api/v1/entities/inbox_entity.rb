# frozen_string_literal: true

module V1
  module Entities
    class InboxEntity < Blueprinter::Base
      identifier :id

      fields :name, :channel_type, :greeting_enabled, :greeting_message, :created_at, :updated_at
    end
  end
end
