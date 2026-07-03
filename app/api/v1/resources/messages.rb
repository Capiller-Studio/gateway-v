# frozen_string_literal: true

module V1
  module Resources
    class Messages < Grape::API
      resource :conversations do
        route_param :conversation_id do
          resource :messages do
            before do
              authenticate_user!
              check_api_feature!
              check_subscription!
              @conversation = current_account.conversations.find(params[:conversation_id])
            end

            desc 'Get a list of messages in a conversation'
            params do
              optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
              optional :per_page, type: Integer, default: 50, values: 1..100
            end
            get do
              authorize!(:read, Message)
              messages = @conversation.messages.includes(:sender, :attachments).order(created_at: :asc)
              paginated = messages.page(params[:page]).per(params[:per_page])

              success(
                data: V1::Entities::MessageEntity.render_as_hash(paginated),
                meta: {
                  current_page: paginated.current_page,
                  total_pages: paginated.total_pages,
                  total_count: paginated.total_count
                }
              )
            end

            desc 'Create a new message in a conversation'
            params do
              requires :content, type: String, desc: 'Message content', allow_blank: false, length: { maximum: 50000 }
            end
            post do
              authorize!(:write, Message)
              message = @conversation.messages.create!(
                account: current_account,
                inbox: @conversation.inbox,
                sender: current_user,
                content: params[:content],
                source: :api
              )

              success(data: V1::Entities::MessageEntity.render_as_hash(message))
            end
          end
        end
      end
    end
  end
end
