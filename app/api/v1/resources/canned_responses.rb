# frozen_string_literal: true

module V1
  module Resources
    class CannedResponses < Grape::API
      resource :canned_responses do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get a list of canned responses'
        params do
          optional :q, type: String, desc: 'Search query for name or code'
          optional :search, type: String, desc: 'Search query for name or code (alias)'
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 50, values: 1..100
        end
        get do
          authorize!(:read, CannedResponse)
          records, meta = current_account.with_shard do
            relation = current_account.canned_responses.where(status: :active).order(created_at: :desc)
            search_term = params[:q].presence || params[:search].presence
            if search_term.present?
              query = "%#{search_term}%"
              relation = relation.where('name ILIKE :q OR identifier ILIKE :q OR description ILIKE :q', q: query)
            end
            paginate(relation, per_page: params[:per_page] || 50)
          end

          success(
            data: V1::Entities::CannedResponseEntity.render_as_hash(records),
            meta: meta
          )
        end

        desc 'Create a new canned response'
        params do
          requires :name, type: String, allow_blank: false, desc: 'Title/name of canned response'
          requires :description, type: String, allow_blank: false, desc: 'Content of canned response'
          optional :identifier, type: String, desc: 'Short code shortcut'
        end
        post do
          authorize!(:write, CannedResponse)
          canned_response = current_account.with_shard do
            attrs = {
              name: params[:name],
              description: params[:description],
              status: :active
            }
            attrs[:identifier] = params[:identifier] if params[:identifier].present?
            current_account.canned_responses.create!(attrs)
          end

          status 201
          success(
            data: V1::Entities::CannedResponseEntity.render_as_hash(canned_response),
            message: 'Canned response created successfully'
          )
        end

        route_param :id do
          desc 'Get a single canned response'
          get do
            authorize!(:read, CannedResponse)
            cr = current_account.with_shard do
              current_account.canned_responses.find(params[:id])
            end

            success(data: V1::Entities::CannedResponseEntity.render_as_hash(cr))
          end

          desc 'Update a canned response'
          params do
            optional :name, type: String, allow_blank: false
            optional :description, type: String, allow_blank: false
            optional :identifier, type: String
          end
          patch do
            authorize!(:write, CannedResponse)
            cr = current_account.with_shard do
              record = current_account.canned_responses.find(params[:id])
              update_attrs = {}
              update_attrs[:name] = params[:name] if params[:name].present?
              update_attrs[:description] = params[:description] if params[:description].present?
              update_attrs[:identifier] = params[:identifier] if params[:identifier].present?

              record.update!(update_attrs) if update_attrs.any?
              record
            end

            success(
              data: V1::Entities::CannedResponseEntity.render_as_hash(cr),
              message: 'Canned response updated successfully'
            )
          end

          desc 'Delete a canned response'
          delete do
            authorize!(:destroy, CannedResponse)
            current_account.with_shard do
              record = current_account.canned_responses.find(params[:id])
              record.destroy!
            end

            success(message: 'Canned response deleted successfully')
          end
        end
      end
    end
  end
end
