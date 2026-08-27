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
          optional :search, type: String, desc: 'Search query for name or code'
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 50, values: 1..100
        end
        get do
          authorize!(:read, CannedResponse)
          records, meta = current_account.with_shard do
            relation = current_account.canned_responses.where(status: :active).order(created_at: :desc)
            if params[:search].present?
              query = "%#{params[:search]}%"
              relation = relation.where('name ILIKE :q OR identifier ILIKE :q OR description ILIKE :q', q: query)
            end
            paginate(relation, per_page: params[:per_page] || 50)
          end

          success(
            data: V1::Entities::CannedResponseEntity.render_as_hash(records),
            meta: meta
          )
        end
      end
    end
  end
end
