# frozen_string_literal: true

module V1
  module Entities
    module Sdk
      class CustomFieldEntity < Blueprinter::Base
        identifier :key do |item|
          if item.is_a?(::CustomFieldResource)
            item.custom_field.key
          elsif item.is_a?(::CustomField)
            item.key
          else
            item[:key] || item['key']
          end
        end

        field :id do |item|
          if item.is_a?(::CustomFieldResource)
            item.custom_field.id
          elsif item.is_a?(::CustomField)
            item.id
          else
            item[:id] || item['id']
          end
        end

        field :key do |item|
          if item.is_a?(::CustomFieldResource)
            item.custom_field.key
          elsif item.is_a?(::CustomField)
            item.key
          else
            item[:key] || item['key']
          end
        end

        field :label do |item, options|
          loc = options[:locale] || I18n.locale
          if item.is_a?(::CustomFieldResource)
            cf = item.custom_field
            cf.translation_for(:label).presence || cf.label.presence || cf.key.titleize
          elsif item.is_a?(::CustomField)
            item.translation_for(:label).presence || item.label.presence || item.key.titleize
          else
            item[:label] || item['label'] || (item[:key] || item['key']).to_s.titleize
          end
        end

        field :placeholder do |item, options|
          loc = options[:locale] || I18n.locale
          if item.is_a?(::CustomFieldResource)
            cf = item.custom_field
            cf.translation_for(:placeholder).presence || cf.placeholder.presence || cf.label.presence || cf.key.titleize
          elsif item.is_a?(::CustomField)
            item.translation_for(:placeholder).presence || item.placeholder.presence || item.label.presence || item.key.titleize
          else
            item[:placeholder] || item['placeholder'] || item[:label] || item['label'] || ''
          end
        end

        field :description do |item, options|
          loc = options[:locale] || I18n.locale
          if item.is_a?(::CustomFieldResource)
            cf = item.custom_field
            cf.translation_for(:description).presence || cf.description
          elsif item.is_a?(::CustomField)
            item.translation_for(:description).presence || item.description
          else
            item[:description] || item['description']
          end
        end

        field :field_type do |item|
          if item.is_a?(::CustomFieldResource)
            item.custom_field.field_type.to_s
          elsif item.is_a?(::CustomField)
            item.field_type.to_s
          else
            (item[:field_type] || item['field_type'] || 'text').to_s
          end
        end

        field :entity_type do |item|
          if item.is_a?(::CustomFieldResource)
            item.custom_field.entity_type.to_s
          elsif item.is_a?(::CustomField)
            item.entity_type.to_s
          else
            (item[:entity_type] || item['entity_type'] || 'customer').to_s
          end
        end

        field :required do |item|
          if item.is_a?(::CustomFieldResource)
            item.required_override.nil? ? item.custom_field.required? : item.required_override
          elsif item.is_a?(::CustomField)
            item.required?
          else
            item.key?(:required) ? item[:required] : (item['required'] || false)
          end
        end

        field :position do |item|
          if item.is_a?(::CustomFieldResource)
            item.position || item.custom_field.position || 0
          elsif item.is_a?(::CustomField)
            item.position || 0
          else
            item[:position] || item['position'] || 0
          end
        end

        field :default_value do |item|
          if item.is_a?(::CustomFieldResource)
            item.custom_field.default_value
          elsif item.is_a?(::CustomField)
            item.default_value
          else
            item[:default_value] || item['default_value']
          end
        end

        field :options do |item, options|
          loc = options[:locale] || I18n.locale
          if item.is_a?(::CustomFieldResource)
            item.custom_field.localized_options(loc)
          elsif item.is_a?(::CustomField)
            item.localized_options(loc)
          else
            item[:options] || item['options'] || []
          end
        end

        field :validations do |item|
          if item.is_a?(::CustomFieldResource)
            item.custom_field.validations || {}
          elsif item.is_a?(::CustomField)
            item.validations || {}
          else
            item[:validations] || item['validations'] || {}
          end
        end
      end
    end
  end
end
