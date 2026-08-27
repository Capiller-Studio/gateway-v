# frozen_string_literal: true

module V1
  module Entities
    class InboxEntity < Blueprinter::Base
      identifier :id

      fields :name, :display_name, :channel_type, :channel_id, :default_locale, :timezone, :status, :created_at, :updated_at
    end
  end
end
