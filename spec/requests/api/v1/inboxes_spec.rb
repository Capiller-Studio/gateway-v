# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Inboxes', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:inbox1) { account.with_shard { create(:inbox, account: account, name: 'Support Inbox') } }
  let!(:inbox2) { account.with_shard { create(:inbox, account: account, name: 'Sales Inbox') } }

  describe 'GET /v1/inboxes' do
    context 'with valid authorization and active subscription' do
      it 'returns list of inboxes for the current account' do
        get '/v1/inboxes', headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']).to be_an(Array)
        expect(json_response['data'].size).to eq(2)
        names = json_response['data'].map { |i| i['name'] }
        expect(names).to include('Support Inbox', 'Sales Inbox')
      end
    end

    context 'when API channel feature is disabled for API key requests' do
      let!(:api_token) { AccessToken.create!(owner: account, token_type: :api_key, token: 'test_api_token_inboxes') }

      it 'returns 403 forbidden' do
        plan.update!(features: { 'channels' => { 'api' => false } })

        get '/v1/inboxes', headers: { 'X-Api-Key' => api_token.token }

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('forbidden')
      end
    end

    context 'when subscription is inactive' do
      it 'returns 402 payment_required' do
        subscription.update!(status: :cancelled)

        get '/v1/inboxes', headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:payment_required)
        expect(json_response['errors'].first['code']).to eq('payment_required')
      end
    end

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get '/v1/inboxes'

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors'].first['code']).to eq('unauthorized')
      end
    end

    context 'when user lacks permission' do
      let!(:agent_user) { create(:user, confirmed_at: Time.current) }
      let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }

      it 'returns 403 forbidden' do
        get '/v1/inboxes', headers: auth_headers(agent_user, account: account)

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('forbidden')
      end
    end
  end

  describe 'GET /v1/inboxes/:id' do
    context 'with valid inbox ID' do
      it 'returns inbox details' do
        get "/v1/inboxes/#{inbox1.id}", headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['id']).to eq(inbox1.id)
        expect(json_response['data']['name']).to eq('Support Inbox')
      end
    end

    context 'with non-existent inbox ID' do
      it 'returns 404 not found' do
        get "/v1/inboxes/#{SecureRandom.uuid}", headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('not_found')
      end
    end

    context 'with inbox belonging to another account' do
      let!(:other_account) { create(:account) }
      let!(:other_inbox) { other_account.with_shard { create(:inbox, account: other_account) } }

      it 'returns 404 not found' do
        get "/v1/inboxes/#{other_inbox.id}", headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('not_found')
      end
    end
  end
end
