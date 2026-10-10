# frozen_string_literal: true

module V1
  module Resources
    class CustomFields < Grape::API
      resource :custom_fields do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get custom field definitions for the account'
        params do
          optional :entity_type, type: String, values: %w[customer conversation], desc: 'Filter by entity type'
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 50, values: 1..100
        end
        get do
          authorize!(:read, CustomField)
          records, meta = current_account.with_shard do
            scope = current_account.custom_fields.order(:position, :created_at)
            scope = scope.where(entity_type: params[:entity_type]) if params[:entity_type].present?
            paginate(scope, per_page: params[:per_page] || 50)
          end

          success(
            data: V1::Entities::CustomFieldEntity.render_as_hash(records),
            meta: meta
          )
        end

        desc 'Create a new custom field definition'
        params do
          requires :key, type: String, allow_blank: false, regexp: /\A[a-z0-9_]+\z/, desc: 'Machine key (lowercase, alphanumeric, underscores)'
          requires :label, type: String, allow_blank: false, desc: 'Human-readable label'
          optional :entity_type, type: String, values: %w[customer conversation], default: 'customer'
          optional :field_type, type: String, values: %w[text email phone number textarea select multi_select checkbox file date url], default: 'text'
          optional :description, type: String
          optional :placeholder, type: String
          optional :required, type: Boolean, default: false
          optional :options, type: Array[String], desc: 'Options for select and multi_select fields'
          optional :validations, type: JSON, default: {}
          optional :configurations, type: JSON, default: {}
        end
        post do
          authorize!(:manage, CustomField)
          field = current_account.with_shard do
            validations = (params[:validations] || {}).dup
            if params[:options].present?
              validations['allowed_values'] = params[:options]
            end

            current_account.custom_fields.create!(
              key: params[:key],
              entity_type: params[:entity_type] || 'customer',
              field_type: params[:field_type] || 'text',
              label: params[:label],
              description: params[:description],
              placeholder: params[:placeholder],
              required: params[:required] || false,
              validations: validations,
              configurations: params[:configurations] || {}
            )
          end

          status 201
          success(
            data: V1::Entities::CustomFieldEntity.render_as_hash(field),
            message: 'Custom field created successfully'
          )
        end

        route_param :id do
          desc 'Get a custom field definition by ID'
          get do
            authorize!(:read, CustomField)
            field = current_account.with_shard do
              current_account.custom_fields.find(params[:id])
            end

            success(data: V1::Entities::CustomFieldEntity.render_as_hash(field))
          end

          desc 'Update a custom field definition'
          params do
            optional :label, type: String, allow_blank: false
            optional :description, type: String
            optional :placeholder, type: String
            optional :required, type: Boolean
            optional :options, type: Array[String]
            optional :validations, type: JSON
            optional :configurations, type: JSON
          end
          patch do
            authorize!(:manage, CustomField)
            field = current_account.with_shard do
              cf = current_account.custom_fields.find(params[:id])
              update_attrs = {}
              update_attrs[:label] = params[:label] if params[:label].present?
              update_attrs[:description] = params[:description] if params.key?(:description)
              update_attrs[:placeholder] = params[:placeholder] if params.key?(:placeholder)
              update_attrs[:required] = params[:required] unless params[:required].nil?
              update_attrs[:configurations] = params[:configurations] if params[:configurations].present?

              if params[:validations].present? || params[:options].present?
                new_validations = (params[:validations] || cf.validations || {}).dup
                new_validations['allowed_values'] = params[:options] if params[:options].present?
                update_attrs[:validations] = new_validations
              end

              cf.update!(update_attrs) if update_attrs.any?
              cf
            end

            success(
              data: V1::Entities::CustomFieldEntity.render_as_hash(field),
              message: 'Custom field updated successfully'
            )
          end

          desc 'Delete a custom field definition'
          delete do
            authorize!(:manage, CustomField)
            current_account.with_shard do
              cf = current_account.custom_fields.find(params[:id])
              cf.destroy!
            end

            success(message: 'Custom field deleted successfully')
          end
        end
      end
    end
  end
end
