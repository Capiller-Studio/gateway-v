# frozen_string_literal: true

module V1
  module Resources
    class Teams < Grape::API
      resource :teams do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get a list of teams for the current account'
        params do
          optional :q, type: String, desc: 'Search term for team name or identifier'
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 50, values: 1..100
        end
        get do
          authorize!(:read, Team)
          records, meta = current_account.with_shard do
            teams = current_account.teams.order(name: :asc)
            if params[:q].present?
              query = "%#{params[:q]}%"
              teams = teams.where('name ILIKE :q OR identifier ILIKE :q', q: query)
            end
            paginate(teams, per_page: params[:per_page] || 50)
          end

          success(
            data: V1::Entities::TeamEntity.render_as_hash(records),
            meta: meta
          )
        end

        desc 'Create a new team'
        params do
          requires :name, type: String, allow_blank: false, desc: 'Team name'
          optional :description, type: String, desc: 'Team description'
          optional :auto_assign, type: Boolean, default: false, desc: 'Enable round-robin auto assignment'
          optional :user_ids, type: Array[String], desc: 'Initial agent user IDs'
        end
        post do
          authorize!(:write, Team)
          team = current_account.with_shard do
            team = current_account.teams.create!(
              name: params[:name],
              description: params[:description],
              auto_assign: params[:auto_assign] || false
            )

            if params[:user_ids].present?
              params[:user_ids].each do |uid|
                team.team_users.find_or_create_by!(user_id: uid)
              end
            end

            team
          end

          status 201
          success(
            data: V1::Entities::TeamEntity.render_as_hash(team),
            message: 'Team created successfully'
          )
        end

        route_param :id do
          desc 'Get a single team'
          get do
            authorize!(:read, Team)
            team = current_account.with_shard { current_account.teams.find(params[:id]) }
            success(data: V1::Entities::TeamEntity.render_as_hash(team))
          end

          desc 'Update a team'
          params do
            optional :name, type: String, allow_blank: false
            optional :description, type: String
            optional :auto_assign, type: Boolean
            optional :status, type: String, values: %w[active inactive archived]
          end
          patch do
            authorize!(:write, Team)
            team = current_account.with_shard do
              t = current_account.teams.find(params[:id])
              update_params = {}
              update_params[:name] = params[:name] if params[:name].present?
              update_params[:description] = params[:description] if params.key?(:description)
              update_params[:auto_assign] = params[:auto_assign] unless params[:auto_assign].nil?
              update_params[:status] = params[:status] if params[:status].present?

              t.update!(update_params) if update_params.any?
              t
            end

            success(
              data: V1::Entities::TeamEntity.render_as_hash(team),
              message: 'Team updated successfully'
            )
          end

          desc 'Delete a team'
          delete do
            authorize!(:destroy, Team)
            current_account.with_shard do
              t = current_account.teams.find(params[:id])
              t.destroy!
            end

            success(message: 'Team deleted successfully')
          end

          # Team Members Subresource
          resource :members do
            desc 'Get members of this team'
            get do
              authorize!(:read, Team)
              members_data = current_account.with_shard do
                team = current_account.teams.find(params[:id])
                team.team_users.includes(:user).map do |tu|
                  {
                    id: tu.id,
                    user_id: tu.user_id,
                    role: tu.role,
                    user: V1::Entities::UserEntity.render_as_hash(tu.user),
                    created_at: tu.created_at
                  }
                end
              end

              success(data: members_data)
            end

            desc 'Add a member to this team'
            params do
              requires :user_id, type: String, allow_blank: false, desc: 'User ID of the agent'
              optional :role, type: String, values: %w[member lead], default: 'member'
            end
            post do
              authorize!(:write, Team)
              tu = current_account.with_shard do
                team = current_account.teams.find(params[:id])
                tu = team.team_users.find_or_initialize_by(user_id: params[:user_id])
                tu.role = params[:role] || :member
                tu.save!
                tu
              end

              status 201
              success(
                data: {
                  id: tu.id,
                  user_id: tu.user_id,
                  role: tu.role,
                  user: V1::Entities::UserEntity.render_as_hash(tu.user)
                },
                message: 'Member added to team successfully'
              )
            end

            desc 'Remove a member from this team'
            delete ':user_id' do
              authorize!(:write, Team)
              current_account.with_shard do
                team = current_account.teams.find(params[:id])
                team.team_users.where(user_id: params[:user_id]).destroy_all
              end

              success(message: 'Member removed from team successfully')
            end
          end
        end
      end
    end
  end
end
