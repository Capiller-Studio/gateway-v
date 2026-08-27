# frozen_string_literal: true

module V1
  module Entities
    class CannedResponseEntity < Blueprinter::Base
      identifier :id

      fields :identifier, :name, :description, :status, :created_at
    end
  end
end
