# frozen_string_literal: true

module V1
  module Resources
    class Sessions < Grape::API
      resource :sessions do
        desc 'Authenticate user and return JWT'
        params do
          requires :email, type: String, desc: 'User email'
          requires :password, type: String, desc: 'User password'
        end
        post do
          user = User.find_by(email: params[:email])

          unless user&.valid_password?(params[:password])
            failure(errors: [{ code: "invalid_credentials", message: "Invalid email or password" }], status: 401)
          end

          token = JwtService.encode(user_id: user.id)

          success(
            data: {
              token: token,
              user: V1::Entities::UserEntity.render_as_hash(user)
            }
          )
        end
      end
    end
  end
end
