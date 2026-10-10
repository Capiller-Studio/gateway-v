# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::CannedResponses CRUD', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:canned_response) do
    account.with_shard do
      create(:canned_response, account: account, name: 'Refund Policy', description: 'Our refund policy is 30 days.')
    end
  end

  describe 'POST /v1/canned_responses' do
    it 'creates a new canned response' do
      post '/v1/canned_responses',
           params: {
             name: 'Greeting Template',
             description: 'Hello! How may I assist you today?',
             identifier: 'greet'
           },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:created)
      expect(json_response['success']).to be true
      expect(json_response['data']['name']).to eq('Greeting Template')
      expect(json_response['data']['description']).to eq('Hello! How may I assist you today?')
    end
  end

  describe 'GET /v1/canned_responses/:id' do
    it 'returns canned response details' do
      get "/v1/canned_responses/#{canned_response.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['id']).to eq(canned_response.id)
      expect(json_response['data']['name']).to eq('Refund Policy')
    end
  end

  describe 'PATCH /v1/canned_responses/:id' do
    it 'updates canned response content' do
      patch "/v1/canned_responses/#{canned_response.id}",
            params: {
              name: 'Updated Refund Policy',
              description: 'Refunds are issued within 14 business days.'
            },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['name']).to eq('Updated Refund Policy')
      expect(json_response['data']['description']).to eq('Refunds are issued within 14 business days.')
    end
  end

  describe 'DELETE /v1/canned_responses/:id' do
    it 'deletes a canned response' do
      delete "/v1/canned_responses/#{canned_response.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(account.with_shard { CannedResponse.find_by(id: canned_response.id) }).to be_nil
    end
  end
end
