# frozen_string_literal: true

module V1
  module Resources
    class CustomAttributes < Grape::API
      resource :custom_attributes do
        before do
          authenticate_user!
          check_subscription!
        end

        desc 'Get custom attribute definitions for the account'
        params do
          optional :entity_type, type: String, values: %w[customer conversation], desc: 'Filter by entity type'
        end
        get do
          fields = current_account.with_shard do
            scope = current_account.custom_fields.order(:position, :created_at)
            scope = scope.where(entity_type: params[:entity_type]) if params[:entity_type].present?
            scope.to_a
          end

          success(data: V1::Entities::CustomFieldEntity.render_as_hash(fields))
        end
      end
    end
  end
end
