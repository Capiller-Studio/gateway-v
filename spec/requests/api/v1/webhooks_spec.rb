# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Webhooks', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:webhook) do
    account.with_shard do
      create(:integration,
             account: account,
             provider: :webhook,
             name: 'Production Webhook',
             status: :active,
             settings: {
               'webhook_url' => 'https://example.com/api/webhooks',
               'subscribed_events' => ['conversation.created', 'message.created']
             },
             credentials: { 'webhook_secret' => 'supersecret123' })
    end
  end

  describe 'Webhooks Management' do
    it 'lists webhooks' do
      get '/v1/webhooks', headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to eq(1)
      expect(json_response['data'].first['url']).to eq('https://example.com/api/webhooks')
      expect(json_response['data'].first['events']).to include('conversation.created')
    end

    it 'creates a new webhook' do
      post '/v1/webhooks',
           params: {
             name: 'Customer Sync Webhook',
             url: 'https://crm.example.com/events',
             events: ['customer.created', 'customer.updated']
           },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:created)
      expect(json_response['success']).to be true
      expect(json_response['data']['name']).to eq('Customer Sync Webhook')
      expect(json_response['data']['url']).to eq('https://crm.example.com/events')
      expect(json_response['data']['events']).to include('customer.created')
    end

    it 'gets a webhook by ID' do
      get "/v1/webhooks/#{webhook.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['id']).to eq(webhook.id)
    end

    it 'updates a webhook' do
      patch "/v1/webhooks/#{webhook.id}",
            params: { name: 'Updated Webhook Name', status: 'disabled' },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['name']).to eq('Updated Webhook Name')
      expect(json_response['data']['status']).to eq('disabled')
    end

    it 'deletes a webhook' do
      delete "/v1/webhooks/#{webhook.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(account.with_shard { Integration.find_by(id: webhook.id) }).to be_nil
    end

    it 'dispatches a test ping delivery' do
      post "/v1/webhooks/#{webhook.id}/test", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['event']).to eq('test.ping')
    end
  end
end
