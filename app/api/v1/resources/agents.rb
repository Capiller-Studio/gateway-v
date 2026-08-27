# frozen_string_literal: true

module V1
  module Resources
    class Agents < Grape::API
      resource :agents do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get a list of agents for the current account'
        params do
          optional :availability, type: String, values: %w[online offline]
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 50, values: 1..100
        end
        get do
          authorize!(:read, AccountUser)
          account_users = current_account.account_users.includes(:user).order(created_at: :asc)
          account_users = account_users.where(availability: params[:availability]) if params[:availability].present?

          records, meta = paginate(account_users, per_page: params[:per_page] || 50)

          success(
            data: V1::Entities::AgentEntity.render_as_hash(records),
            meta: meta
          )
        end
      end
    end
  end
end
