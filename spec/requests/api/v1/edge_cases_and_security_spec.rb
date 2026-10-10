# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1 Gateway API Edge Cases & Security', type: :request do
  let!(:account_a) { create(:account) }
  let!(:account_b) { create(:account) }

  let!(:user_a) { create(:user, email: 'usera@example.com', confirmed_at: Time.current) }
  let!(:user_b) { create(:user, email: 'userb@example.com', confirmed_at: Time.current) }

  let!(:account_user_a) { create(:account_user, account: account_a, user: user_a, owner: true) }
  let!(:account_user_b) { create(:account_user, account: account_b, user: user_b, owner: true) }

  let!(:plan_active) { create(:plan, name: "Active #{SecureRandom.hex(4)}", features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:plan_no_api) { create(:plan, name: "No API #{SecureRandom.hex(4)}", features: { 'channels' => { 'api' => false } }, limits: { 'channels' => 100, 'users' => 100 }) }

  let!(:sub_a) { create(:subscription, account: account_a, plan: plan_active, status: :active) }
  let!(:sub_b) { create(:subscription, account: account_b, plan: plan_active, status: :active) }

  let!(:inbox_a) { account_a.with_shard { create(:inbox, account: account_a, name: 'Inbox A') } }
  let!(:inbox_b) { account_b.with_shard { create(:inbox, account: account_b, name: 'Inbox B') } }

  let!(:conv_a) { account_a.with_shard { create(:conversation, account: account_a, inbox: inbox_a, status: :active) } }
  let!(:conv_b) { account_b.with_shard { create(:conversation, account: account_b, inbox: inbox_b, status: :active) } }

  let!(:customer_b) { account_b.with_shard { create(:customer, account: account_b, name: 'Tenant B Customer') } }
  let!(:macro_b) do
    account_b.with_shard do
      create(:macro, account: account_b, name: 'Secret Macro B', visibility: :account_wide,
             actions: [{ 'action' => 'set_status', 'params' => { 'status' => 'resolved' } }])
    end
  end

  describe 'Cross-Tenant Isolation (Anti-Data-Leak Guards)' do
    it 'prevents User A from viewing Tenant B conversation' do
      get "/v1/conversations/#{conv_b.id}", headers: auth_headers(user_a, account: account_a)

      expect(response).to have_http_status(:not_found)
      expect(json_response['success']).to be false
      expect(json_response['errors'].first['code']).to eq('not_found')
    end

    it 'prevents User A from viewing Tenant B customer' do
      get "/v1/customers/#{customer_b.id}", headers: auth_headers(user_a, account: account_a)

      expect(response).to have_http_status(:not_found)
      expect(json_response['success']).to be false
    end

    it 'prevents User A from viewing or executing Tenant B macro' do
      get "/v1/macros/#{macro_b.id}", headers: auth_headers(user_a, account: account_a)
      expect(response).to have_http_status(:not_found)

      post "/v1/macros/#{macro_b.id}/execute",
           params: { conversation_id: conv_a.id },
           headers: auth_headers(user_a, account: account_a)
      expect(response).to have_http_status(:not_found)
    end

    it 'rejects requests attempting to switch to an unauthorized foreign account via X-Account-Id' do
      get '/v1/conversations', headers: auth_headers(user_a).merge('X-Account-Id' => account_b.id)

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['success']).to be false
    end
  end

  describe 'Subscription and Plan Feature Enforcement' do
    it 'returns 402 payment_required when subscription is cancelled or unpaid' do
      sub_a.update!(status: :past_due)

      get '/v1/conversations', headers: auth_headers(user_a, account: account_a)

      expect(response).to have_http_status(:payment_required)
      expect(json_response['success']).to be false
      expect(json_response['errors'].first['code']).to eq('payment_required')
    end

    it 'returns 403 forbidden when API feature is disabled for API Key requests' do
      # Switch plan to no API channel
      sub_a.update!(plan: plan_no_api)
      api_key = AccessToken.create!(owner: account_a, token: 'key-test-disabled', token_type: :api_key)

      get '/v1/conversations', headers: { 'X-Api-Key' => api_key.token }

      expect(response).to have_http_status(:forbidden)
      expect(json_response['success']).to be false
      expect(json_response['errors'].first['code']).to eq('forbidden')
    end
  end

  describe 'Invalid Input & Edge Cases' do
    it 'handles extreme pagination numbers safely' do
      get '/v1/conversations',
          params: { page: 999999, per_page: 100 },
          headers: auth_headers(user_a, account: account_a)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']).to eq([])
      expect(json_response['meta']['current_page']).to eq(999999)
    end

    it 'clamps per_page to maximum 100 records' do
      get '/v1/conversations',
          params: { per_page: 500 },
          headers: auth_headers(user_a, account: account_a)

      # Grape params validation or paginate clamping
      if response.status == 200
        expect(json_response['meta']['per_page']).to be <= 100
      else
        expect(response).to have_http_status(:bad_request).or have_http_status(:unprocessable_entity)
      end
    end

    it 'returns clean 404 for non-existent UUIDs' do
      fake_uuid = SecureRandom.uuid
      get "/v1/conversations/#{fake_uuid}", headers: auth_headers(user_a, account: account_a)

      expect(response).to have_http_status(:not_found)
      expect(json_response['success']).to be false
      expect(json_response['errors']).to be_an(Array)
    end

    it 'returns clean 422 validation errors for invalid conversation creation params' do
      post '/v1/conversations',
           params: { inbox_id: inbox_a.id, status: 'invalid_status_enum' },
           headers: auth_headers(user_a, account: account_a)

      expect(response).to have_http_status(:bad_request).or have_http_status(:unprocessable_entity)
      expect(json_response['success']).to be false
      expect(json_response['errors']).to be_present
    end
  end
end
