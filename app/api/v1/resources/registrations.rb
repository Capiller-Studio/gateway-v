# frozen_string_literal: true

module V1
  module Resources
    class Registrations < Grape::API
      resource :registrations do
        before { authenticate_mobile_app! }

        desc 'Register a new user, account, or affiliate profile'
        params do
          requires :email, type: String, regexp: URI::MailTo::EMAIL_REGEXP, desc: 'User email'
          requires :password, type: String, allow_blank: false, password_format: true, desc: 'User password'
          optional :first_name, type: String, length: { maximum: 255 }
          optional :last_name, type: String, length: { maximum: 255 }
          optional :account_name, type: String, length: { maximum: 255 }, desc: 'Name for new account (creates account with owner role)'
          optional :as_affiliate, type: Boolean, default: false, desc: 'Also create an affiliate profile'
          optional :invitation_token, type: String, desc: 'Token for joining an existing account'
        end
        post do
          result = Accounts::RegistrationService.call(**declared(params, include_missing: false).symbolize_keys)

          unless result.success?
            failure(errors: result.errors, status: 422)
          end

          token = JwtService.encode({ user_id: result.user.id })

          success(
            data: {
              token: token,
              user: V1::Entities::UserEntity.render_as_hash(result.user, view: :extended),
              account: result.account ? V1::Entities::AccountEntity.render_as_hash(result.account) : nil
            }
          )
        end
      end
    end
  end
end
