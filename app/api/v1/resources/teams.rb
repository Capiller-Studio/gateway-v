# frozen_string_literal: true

module V1
  module Resources
    class Teams < Grape::API
      resource :teams do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get a list of teams for the current account'
        params do
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 50, values: 1..100
        end
        get do
          authorize!(:read, Team)
          records, meta = current_account.with_shard do
            teams = current_account.teams.order(name: :asc)
            paginate(teams, per_page: params[:per_page] || 50)
          end

          success(
            data: V1::Entities::TeamEntity.render_as_hash(records),
            meta: meta
          )
        end
      end
    end
  end
end
