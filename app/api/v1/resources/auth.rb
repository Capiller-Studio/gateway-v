# frozen_string_literal: true

module V1
  module Resources
    class Auth < Grape::API
      resource :auth do
        desc 'Authenticate user with email and password'
        params do
          requires :email, type: String, regexp: URI::MailTo::EMAIL_REGEXP, desc: 'User email'
          requires :password, type: String, allow_blank: false, desc: 'User password'
        end
        post :login do
          status 200
          user = User.find_by(email: params[:email].to_s.downcase.strip)

          unless user&.valid_password?(params[:password])
            failure(
              errors: [{ code: 'invalid_credentials', message: I18n.t('gateway.errors.invalid_credentials', default: 'Invalid email or password') }],
              status: 401
            )
          end

          account = user.accounts.first
          token = JwtService.encode({ user_id: user.id, account_id: account&.id })

          success(
            data: {
              token: token,
              user: V1::Entities::UserEntity.render_as_hash(user, view: :extended, is_self: true),
              account: account ? V1::Entities::AccountEntity.render_as_hash(account) : nil
            }
          )
        end

        desc 'Invalidate current session'
        delete :logout do
          authenticate_user!
          success(message: 'Logged out successfully')
        end

        desc 'Refresh active JWT session'
        post :refresh do
          status 200
          authenticate_user!
          account_id = current_account&.id || current_user.accounts.first&.id
          new_token = JwtService.encode({ user_id: current_user.id, account_id: account_id })

          success(
            data: {
              token: new_token,
              user: V1::Entities::UserEntity.render_as_hash(current_user, view: :extended, is_self: true),
              account: current_account ? V1::Entities::AccountEntity.render_as_hash(current_account) : nil
            }
          )
        end

        desc 'Register a new user and account'
        params do
          requires :email, type: String, regexp: URI::MailTo::EMAIL_REGEXP, desc: 'User email'
          requires :password, type: String, allow_blank: false, password_format: true, desc: 'User password'
          optional :first_name, type: String, length: { maximum: 255 }
          optional :last_name, type: String, length: { maximum: 255 }
          optional :account_name, type: String, length: { maximum: 255 }, desc: 'Name for new account'
          optional :as_affiliate, type: Boolean, default: false, desc: 'Also create an affiliate profile'
          optional :invitation_token, type: String, desc: 'Token for joining an existing account'
        end
        post :register do
          authenticate_mobile_app!

          result = Accounts::RegistrationService.call(**declared(params, include_missing: false).symbolize_keys)

          unless result.success?
            failure(errors: result.errors, status: 422)
          end

          token = JwtService.encode({ user_id: result.user.id, account_id: result.account&.id })

          success(
            data: {
              token: token,
              user: V1::Entities::UserEntity.render_as_hash(result.user, view: :extended, is_self: true),
              account: result.account ? V1::Entities::AccountEntity.render_as_hash(result.account) : nil
            }
          )
        end

        resource :password do
          desc 'Send password reset instructions'
          params do
            requires :email, type: String, desc: 'User email address', regexp: URI::MailTo::EMAIL_REGEXP
          end
          post :forgot do
            user = User.find_by(email: params[:email].downcase.strip)
            user&.send_reset_password_instructions

            success(message: 'If your email is registered with us, you will receive password reset instructions.')
          end

          desc 'Reset password with reset token'
          params do
            requires :reset_password_token, type: String, desc: 'Password reset token', allow_blank: false
            requires :password, type: String, desc: 'New password', password_format: true
            requires :password_confirmation, type: String, desc: 'Password confirmation'
          end
          post :reset do
            if params[:password] != params[:password_confirmation]
              error!({
                success: false,
                errors: [{ code: 'validation_error', field: 'password_confirmation', message: 'does not match password' }]
              }, 422)
            end

            user = User.reset_password_by_token(
              reset_password_token: params[:reset_password_token],
              password: params[:password],
              password_confirmation: params[:password_confirmation]
            )

            if user.errors.empty?
              success(message: 'Password has been successfully reset. Please log in with your new password.')
            else
              error!({
                success: false,
                errors: user.errors.map { |err| { code: 'record_invalid', field: err.attribute.to_s, message: err.message } }
              }, 422)
            end
          end
        end
      end
    end
  end
end
