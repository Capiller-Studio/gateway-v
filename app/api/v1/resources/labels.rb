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

          success(data: V1::Entities::LabelEntity.render_as_hash(label))
        end
      end
    end
  end
end
