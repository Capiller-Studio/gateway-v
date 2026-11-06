# frozen_string_literal: true

module V1
  module Resources
    class Me < Grape::API
      before do
        authenticate_user!
      end

      resource :me do
        desc 'Get current user profile, roles, and account context'
        get do
          success(
            data: {
              user: V1::Entities::UserEntity.render_as_hash(current_user, view: :extended, is_self: true),
              accounts: V1::Entities::AccountEntity.render_as_hash(current_user.accounts),
              current_account: current_account ? V1::Entities::AccountEntity.render_as_hash(current_account) : nil,
              availability: current_account_user&.availability,
              role: current_account_user&.owner? ? 'owner' : (current_account_user&.roles&.first&.name || 'agent')
            }
          )
        end

        desc 'Update current user profile'
        params do
          optional :first_name, type: String, allow_blank: false
          optional :last_name, type: String, allow_blank: false
          optional :display_name, type: String
          optional :locale, type: String
          optional :password, type: String, password_format: true
          optional :password_confirmation, type: String
          optional :current_password, type: String
        end
        patch :profile do
          user_params = {}
          user_params[:first_name] = params[:first_name] if params[:first_name].present?
          user_params[:last_name] = params[:last_name] if params[:last_name].present?
          user_params[:display_name] = params[:display_name] if params[:display_name].present?
          user_params[:locale] = params[:locale] if params[:locale].present?

          if params[:password].present?
            if params[:current_password].blank? || !current_user.valid_password?(params[:current_password])
              error!({
                success: false,
                errors: [{ code: 'validation_error', field: 'current_password', message: 'is invalid' }]
              }, 422)
            end

            if params[:password] != params[:password_confirmation]
              error!({
                success: false,
                errors: [{ code: 'validation_error', field: 'password_confirmation', message: 'does not match password' }]
              }, 422)
            end

            user_params[:password] = params[:password]
            user_params[:password_confirmation] = params[:password_confirmation]
          end

          current_user.update!(user_params)

          success(data: V1::Entities::UserEntity.render_as_hash(current_user, view: :extended, is_self: true))
        end

        desc 'Update agent availability status'
        params do
          requires :availability, type: String, values: %w[online offline]
        end
        patch :availability do
          if current_account_user.nil?
            error!({
              success: false,
              errors: [{ code: 'not_found', message: 'Account membership not found' }]
            }, 404)
          end

          current_account_user.update!(
            availability: params[:availability],
            availability_changed_at: Time.current
          )

          success(
            data: {
              availability: current_account_user.availability,
              availability_changed_at: current_account_user.availability_changed_at
            }
          )
        end

        desc 'Switch active tenant account'
        params do
          requires :account_id, type: String, desc: 'Target Account ID', allow_blank: false
        end
        post 'switch_account/:account_id' do
          status 200
          target_account = current_user.accounts.find_by(id: params[:account_id])

          unless target_account
            error!({
              success: false,
              errors: [{ code: 'forbidden', message: 'You are not a member of the requested account.' }]
            }, 403)
          end

          new_token = JwtService.encode({ user_id: current_user.id, account_id: target_account.id })

          success(
            data: {
              token: new_token,
              account: V1::Entities::AccountEntity.render_as_hash(target_account)
            },
            message: "Switched to account #{target_account.name} successfully"
          )
        end

        desc 'Get real-time ActionCable WebSocket connection details'
        get :cable_token do
          cable_url = ENV['ACTION_CABLE_URL'].presence || 'wss://ws-rely.capiller.com'
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
