# frozen_string_literal: true

module V1
  module Resources
    class Me < Grape::API
      before do
        authenticate_user!
      end

      resource :me do
        desc 'Get current user profile and account context'
        get do
          success(
            data: {
              user: V1::Entities::UserEntity.render_as_hash(current_user, view: :extended, is_self: true),
              accounts: V1::Entities::AccountEntity.render_as_hash(current_user.accounts),
              current_account: current_account ? V1::Entities::AccountEntity.render_as_hash(current_account) : nil
            }
          )
        end

        desc 'Get real-time ActionCable WebSocket connection details'
        get :cable_token do
          cable_url = ENV['ACTION_CABLE_URL'].presence || 'wss://ws.deskbolic.com'
          success(
            data: {
              connection_token: current_user.connection_token,
              action_cable_url: cable_url,
              channels: [
                { name: 'SubscriptionChannel', params: { connection_token: current_user.connection_token } }
              ]
            }
          )
        end
      end
    end
  end
end

