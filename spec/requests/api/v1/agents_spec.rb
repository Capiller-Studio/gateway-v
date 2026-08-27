# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Agents', type: :request do
  let!(:account) { create(:account) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:owner_user) { create(:user, first_name: 'Alice', email: 'alice@example.com', confirmed_at: Time.current) }
  let!(:agent_user) { create(:user, first_name: 'Bob', email: 'bob@example.com', confirmed_at: Time.current) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true, availability: :online) }
  let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false, availability: :offline) }

  describe 'GET /v1/agents' do
    context 'when authenticated with active subscription' do
      it 'returns list of agents with availability status' do
        get '/v1/agents', headers: auth_headers(owner_user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(2)
        expect(json_response['data'].map { |a| a['user']['email'] }).to include('alice@example.com', 'bob@example.com')
      end

      it 'filters agents by availability' do
        get '/v1/agents', params: { availability: 'online' }, headers: auth_headers(owner_user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(1)
        expect(json_response['data'].first['user']['email']).to eq('alice@example.com')
      end
    end

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get '/v1/agents'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
