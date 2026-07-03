# frozen_string_literal: true

module V1
  module Entities
    class CustomerEntity < Blueprinter::Base
      identifier :id

      fields :name, :email, :phone_number, :avatar_url, :custom_attributes, :created_at, :updated_at
    end
  end
end
