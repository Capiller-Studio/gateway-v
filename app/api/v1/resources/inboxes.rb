# frozen_string_literal: true

module V1
  module Resources
    class Inboxes < Grape::API
      resource :inboxes do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get a list of inboxes for the current account'
        get do
          authorize!(:read, Inbox)
          inboxes = current_account.with_shard { current_account.inboxes.to_a }
          success(data: V1::Entities::InboxEntity.render_as_hash(inboxes))
        end

        desc 'Get a single inbox'
        params do
          requires :id, type: String, desc: 'Inbox ID', allow_blank: false
        end
        get ':id' do
          authorize!(:read, Inbox)
          inbox = current_account.with_shard { current_account.inboxes.find(params[:id]) }
          success(data: V1::Entities::InboxEntity.render_as_hash(inbox))
        end
      end
    end
  end
end
