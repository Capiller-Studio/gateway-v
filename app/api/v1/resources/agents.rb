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
          optional :q, type: String, desc: 'Search by name or email'
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 50, values: 1..100
        end
        get do
          authorize!(:read, AccountUser)
          account_users = current_account.account_users.includes(:user).order(created_at: :asc)
          account_users = account_users.where(availability: params[:availability]) if params[:availability].present?

          if params[:q].present?
            query = "%#{params[:q]}%"
            matching_user_ids = User.where('email ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q', q: query).pluck(:id)
            account_users = account_users.where(user_id: matching_user_ids)
          end

          records, meta = paginate(account_users, per_page: params[:per_page] || 50)

          success(
            data: V1::Entities::AgentEntity.render_as_hash(records),
            meta: meta
          )
        end

        desc 'Invite a new agent to the account'
        params do
          requires :email, type: String, allow_blank: false, regexp: URI::MailTo::EMAIL_REGEXP, desc: 'Agent email address'
          optional :role_ids, type: Array[String], desc: 'Role IDs to grant'
        end
        post do
          authorize!(:invite, AccountUser)

          # Check seat limit
          if current_account.respond_to?(:users_limit_reached?) && current_account.users_limit_reached?
            error!({
              success: false,
              errors: [{ code: 'limit_exceeded', field: 'base', message: 'Agent seat limit reached for your plan' }]
            }, 402)
          end

          target_role_ids = params[:role_ids]
          if target_role_ids.blank?
            default_role = current_account.with_shard do
              current_account.roles.find_by(identifier: 'agent') ||
                current_account.roles.first ||
                current_account.roles.create!(name: 'Agent', identifier: 'agent', permissions: {})
            end
            target_role_ids = [default_role.id.to_s]
          end

          invitation = Accounts::Invitations::Create.call(
            account: current_account,
            invited_by: current_user,
            email: params[:email],
            role_ids: target_role_ids
          )

          status 201
          success(
            data: {
              id: invitation.id,
              email: invitation.email,
              status: invitation.status,
              created_at: invitation.created_at
            },
            message: 'Agent invitation sent successfully'
          )
        end

        route_param :id do
          desc 'Get an agent by ID'
          get do
            authorize!(:read, AccountUser)
            account_user = current_account.account_users.includes(:user).find(params[:id])
            success(data: V1::Entities::AgentEntity.render_as_hash(account_user))
          end

          desc 'Update an agent'
          params do
            optional :availability, type: String, values: %w[online offline]
            optional :role_ids, type: Array[String], desc: 'Updated role IDs'
          end
          patch do
            authorize!(:manage, AccountUser)
            account_user = current_account.account_users.find(params[:id])

            if params[:availability].present?
              account_user.update!(
                availability: params[:availability],
                availability_changed_at: Time.current
              )
            end

            if params[:role_ids].present?
              account_user.assign_roles(params[:role_ids])
            end

            success(
              data: V1::Entities::AgentEntity.render_as_hash(account_user.reload),
              message: 'Agent updated successfully'
            )
          end

          desc 'Remove an agent from the account'
          delete do
            authorize!(:destroy, AccountUser)
            account_user = current_account.account_users.find(params[:id])

            if account_user.owner?
              error!({
                success: false,
                errors: [{ code: 'forbidden', field: 'base', message: 'Account owner cannot be removed' }]
              }, 422)
            end

            account_user.destroy!
            success(message: 'Agent removed from account successfully')
          end
        end
      end
    end
  end
end
