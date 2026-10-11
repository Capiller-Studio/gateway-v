# frozen_string_literal: true

module V1
  module Entities
    module Sdk
      class DeviceEntity < Blueprinter::Base
        identifier :id

        fields :push_token, :platform, :push_provider, :created_at, :last_seen_at
      end
    end
  end
end
