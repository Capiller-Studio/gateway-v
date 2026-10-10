# frozen_string_literal: true

module V1
  module Entities
    class ApiKeyEntity < Blueprinter::Base
      identifier :id

      fields :token, :token_type, :valid_till, :created_at
    end
  end
end
