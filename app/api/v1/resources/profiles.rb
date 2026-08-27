# frozen_string_literal: true

module V1
  module Resources
    class Profiles < Grape::API
      resource :profile do
        before do
          authenticate_user!
        end

        desc 'Get current user profile'
        get do
          success(
            data: {
              user: V1::Entities::UserEntity.render_as_hash(current_user),
              current_account: V1::Entities::AccountEntity.render_as_hash(current_account),
              availability: current_account_user&.availability
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
        patch do
          user_params = {}
          user_params[:first_name] = params[:first_name] if params[:first_name].present?
          user_params[:last_name] = params[:last_name] if params[:last_name].present?
          user_params[:display_name] = params[:display_name] if params[:display_name].present?
          user_params[:locale] = params[:locale] if params[:locale].present?

          if params[:password].present?
            if params[:current_password].blank? || !current_user.valid_password?(params[:current_password])
              error!({ errors: [{ field: 'current_password', message: 'is invalid' }] }, 422)
            end

            if params[:password] != params[:password_confirmation]
              error!({ errors: [{ field: 'password_confirmation', message: 'does not match password' }] }, 422)
            end

            user_params[:password] = params[:password]
            user_params[:password_confirmation] = params[:password_confirmation]
          end

          current_user.update!(user_params)

          success(data: V1::Entities::UserEntity.render_as_hash(current_user))
        end

        desc 'Update agent availability status'
        params do
          requires :availability, type: String, values: %w[online offline]
        end
        patch :availability do
          if current_account_user.nil?
            error!({ errors: [{ code: 'not_found', message: 'Account membership not found' }] }, 404)
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
      end
    end
  end
end
