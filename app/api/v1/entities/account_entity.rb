# frozen_string_literal: true

module V1
  module Entities
    class AccountEntity < Blueprinter::Base
      identifier :id
      fields :name, :identifier, :status, :created_at
    end
  end
end
