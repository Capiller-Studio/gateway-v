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
              user: V1::Entities::UserEntity.render_as_hash(current_user, view: :extended),
              accounts: V1::Entities::AccountEntity.render_as_hash(current_user.accounts),
              current_account: current_account ? V1::Entities::AccountEntity.render_as_hash(current_account) : nil
            }
          )
        end
      end
    end
  end
end
