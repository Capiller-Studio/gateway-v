# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Agents', type: :request do
  let!(:account) { create(:account) }
  let!(:owner_user) { create(:user, email: 'owner@example.com', confirmed_at: Time.current) }
  let!(:agent_user) { create(:user, email: 'agent@example.com', first_name: 'Sarah', confirmed_at: Time.current) }

  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true, availability: :offline) }
  let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, availability: :online) }

  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  describe 'GET /v1/agents' do
    it 'returns list of agents for the account' do
      get '/v1/agents', headers: auth_headers(owner_user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to eq(2)
      expect(json_response['meta']['pagination']).to be_present
    end

    it 'filters agents by availability' do
      get '/v1/agents', params: { availability: 'online' }, headers: auth_headers(owner_user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to eq(1)
      expect(json_response['data'].first['id']).to eq(agent_account_user.id)
    end

    it 'searches agents by name or email' do
      get '/v1/agents', params: { q: 'Sarah' }, headers: auth_headers(owner_user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to eq(1)
      expect(json_response['data'].first['id']).to eq(agent_account_user.id)
    end
  end

  describe 'POST /v1/agents' do
    it 'invites a new agent' do
      post '/v1/agents',
           params: { email: 'newagent@example.com' },
           headers: auth_headers(owner_user, account: account)

      expect(response).to have_http_status(:created)
      expect(json_response['success']).to be true
      expect(json_response['data']['email']).to eq('newagent@example.com')
      expect(json_response['data']['status']).to eq('pending')
    end

    it 'rejects invalid email address' do
      post '/v1/agents',
           params: { email: 'not-an-email' },
           headers: auth_headers(owner_user, account: account)

      expect(response).to have_http_status(:bad_request).or have_http_status(:unprocessable_entity)
      expect(json_response['success']).to be false
    end
  end

  describe 'GET /v1/agents/:id' do
    it 'returns agent details' do
      get "/v1/agents/#{agent_account_user.id}", headers: auth_headers(owner_user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['id']).to eq(agent_account_user.id)
      expect(json_response['data']['user']['email']).to eq('agent@example.com')
    end
  end

  describe 'PATCH /v1/agents/:id' do
    it 'updates agent availability' do
      patch "/v1/agents/#{agent_account_user.id}",
            params: { availability: 'offline' },
            headers: auth_headers(owner_user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['availability']).to eq('offline')
    end
  end

  describe 'DELETE /v1/agents/:id' do
    it 'removes an agent from the account' do
      delete "/v1/agents/#{agent_account_user.id}", headers: auth_headers(owner_user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(AccountUser.find_by(id: agent_account_user.id)).to be_nil
    end

    it 'prevents removing the account owner' do
      delete "/v1/agents/#{owner_account_user.id}", headers: auth_headers(owner_user, account: account)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['success']).to be false
      expect(json_response['errors'].first['message']).to include('owner cannot be removed')
    end
  end
end
