# frozen_string_literal: true

module V1
  module Entities
    class CustomFieldEntity < Blueprinter::Base
      identifier :id

      fields :key, :entity_type, :field_type, :required, :position, :validations, :configurations, :created_at

      field :label do |cf|
        cf.label
      end

      field :placeholder do |cf|
        cf.placeholder
      end

      field :description do |cf|
        cf.description
      end

      field :options do |cf|
        cf.localized_options(I18n.locale)
      end
    end
  end
end
