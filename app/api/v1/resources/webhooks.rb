# frozen_string_literal: true

module V1
  module Resources
    class Webhooks < Grape::API
      resource :webhooks do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get list of configured webhooks'
        params do
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 50, values: 1..100
        end
        get do
          authorize!(:manage, Integration)
          records, meta = current_account.with_shard do
            webhooks = current_account.integrations.where(provider: :webhook).order(created_at: :desc)
            paginate(webhooks, per_page: params[:per_page] || 50)
          end

          success(
            data: V1::Entities::WebhookEntity.render_as_hash(records),
            meta: meta
          )
        end

        desc 'Create a new webhook'
        params do
          requires :url, type: String, allow_blank: false, desc: 'Destination webhook URL'
          optional :name, type: String, default: 'Webhook', desc: 'Webhook name'
          optional :events, type: Array[String], default: ['conversation.created', 'message.created'], desc: 'Subscribed event types'
          optional :inbox_ids, type: Array[String], desc: 'Filter events by inbox IDs'
        end
        post do
          authorize!(:manage, Integration)
          webhook = current_account.with_shard do
            current_account.integrations.create!(
              provider: :webhook,
              name: params[:name] || 'Webhook',
              status: :active,
              settings: {
                'webhook_url' => params[:url],
                'subscribed_events' => params[:events] || [],
                'subscribed_inboxes' => params[:inbox_ids] || []
              },
              credentials: {
                'webhook_secret' => SecureRandom.hex(24)
              }
            )
          end

          status 201
          success(
            data: V1::Entities::WebhookEntity.render_as_hash(webhook),
            message: 'Webhook created successfully'
          )
        end

        route_param :id do
          desc 'Get a webhook by ID'
          get do
            authorize!(:manage, Integration)
            webhook = current_account.with_shard do
              current_account.integrations.where(provider: :webhook).find(params[:id])
            end

            success(data: V1::Entities::WebhookEntity.render_as_hash(webhook))
          end

          desc 'Update a webhook'
          params do
            optional :name, type: String
            optional :url, type: String
            optional :events, type: Array[String]
            optional :inbox_ids, type: Array[String]
            optional :status, type: String, values: %w[active disabled]
          end
          patch do
            authorize!(:manage, Integration)
            webhook = current_account.with_shard do
              w = current_account.integrations.where(provider: :webhook).find(params[:id])
              settings = (w.settings || {}).dup
              settings['webhook_url'] = params[:url] if params[:url].present?
              settings['subscribed_events'] = params[:events] if params[:events].present?
              settings['subscribed_inboxes'] = params[:inbox_ids] if params[:inbox_ids].present?

              update_attrs = { settings: settings }
              update_attrs[:name] = params[:name] if params[:name].present?
              update_attrs[:status] = params[:status] if params[:status].present?

              w.update!(update_attrs)
              w
            end

            success(
              data: V1::Entities::WebhookEntity.render_as_hash(webhook),
              message: 'Webhook updated successfully'
            )
          end

          desc 'Delete a webhook'
          delete do
            authorize!(:manage, Integration)
            current_account.with_shard do
              w = current_account.integrations.where(provider: :webhook).find(params[:id])
              w.destroy!
            end

            success(message: 'Webhook deleted successfully')
          end

          desc 'Send a test ping delivery to webhook'
          post :test do
            authorize!(:manage, Integration)
            delivery = current_account.with_shard do
              w = current_account.integrations.where(provider: :webhook).find(params[:id])
              del = Webhook::Delivery.create!(
                account: current_account,
                resource: w,
                event_name: 'test.ping',
                endpoint_url: w.webhook_url,
                request_payload: {
                  event: 'test.ping',
                  account_id: current_account.id,
                  timestamp: Time.current.iso8601
                }
              )
              Integrations::Webhooks::BroadcasterWorker.perform_async(current_account.id, del.id) rescue nil
              del
            end

            status 200
            success(
              data: { delivery_id: delivery.id, event: delivery.event_name, status: delivery.status },
              message: 'Test webhook delivery queued successfully'
            )
          end
        end
      end
    end
  end
end
