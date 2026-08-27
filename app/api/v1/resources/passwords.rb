# frozen_string_literal: true

module V1
  module Resources
    class Passwords < Grape::API
      resource :passwords do
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
            error!({ errors: [{ field: 'password_confirmation', message: 'does not match password' }] }, 422)
          end

          user = User.reset_password_by_token(
            reset_password_token: params[:reset_password_token],
            password: params[:password],
            password_confirmation: params[:password_confirmation]
          )

          if user.errors.empty?
            success(message: 'Password has been successfully reset. Please log in with your new password.')
          else
            error!({ errors: user.errors.map { |err| { field: err.attribute.to_s, message: err.message } } }, 422)
          end
        end
      end
    end
  end
end
