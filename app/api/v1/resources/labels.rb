# frozen_string_literal: true

module V1
  module Resources
    class Labels < Grape::API
      resource :labels do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get a list of labels for the account'
        params do
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 50, values: 1..100
        end
        get do
          authorize!(:read, Label)
          records, meta = current_account.with_shard do
            labels = current_account.labels.order(title: :asc)
            paginate(labels, per_page: params[:per_page] || 50)
          end

          success(
            data: V1::Entities::LabelEntity.render_as_hash(records),
            meta: meta
          )
        end

        desc 'Create a new label'
        params do
          requires :title, type: String, desc: 'Label title', allow_blank: false
          optional :color, type: String, desc: 'Hex color code', default: '#3B82F6'
          optional :description, type: String, desc: 'Label description'
        end
        post do
          authorize!(:write, Label)
          label = current_account.with_shard do
            current_account.labels.create!(
              title: params[:title],
              color: params[:color],
              description: params[:description]
            )
          end

          status 201
          success(
            data: V1::Entities::LabelEntity.render_as_hash(label),
            message: 'Label created successfully'
          )
        end

        route_param :id do
          desc 'Get a single label by ID'
          get do
            authorize!(:read, Label)
            label = current_account.with_shard do
              current_account.labels.find(params[:id])
            end

            success(data: V1::Entities::LabelEntity.render_as_hash(label))
          end

          desc 'Update a label'
          params do
            optional :title, type: String, allow_blank: false
            optional :color, type: String
            optional :description, type: String
          end
          patch do
            authorize!(:write, Label)
            label = current_account.with_shard do
              l = current_account.labels.find(params[:id])
              update_attrs = {}
              update_attrs[:title] = params[:title] if params[:title].present?
              update_attrs[:color] = params[:color] if params[:color].present?
              update_attrs[:description] = params[:description] if params.key?(:description)

              l.update!(update_attrs) if update_attrs.any?
              l
            end

            success(
              data: V1::Entities::LabelEntity.render_as_hash(label),
              message: 'Label updated successfully'
            )
          end

          desc 'Delete a label'
          delete do
            authorize!(:write, Label)
            current_account.with_shard do
              l = current_account.labels.find(params[:id])
              l.destroy!
            end

            success(message: 'Label deleted successfully')
          end
        end
      end
    end
  end
end
