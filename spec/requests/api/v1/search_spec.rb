# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Searches', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let!(:inbox) { account.with_shard { create(:inbox, account: account, name: 'Support') } }

  let!(:conversation) do
    account.with_shard do
      create(:conversation, account: account, inbox: inbox, title: 'Urgent Billing Issue', identifier: 'CONV-101')
    end
  end

  let!(:message) do
    account.with_shard do
      create(:message, account: account, inbox: inbox, conversation: conversation, sender: user, content: 'Need refund for payment')
    end
  end

  describe 'GET /v1/search' do
    it 'returns 401 when unauthenticated' do
      get '/v1/search', params: { q: 'refund' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns matched conversations and messages' do
      get '/v1/search', params: { q: 'Billing' }, headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['conversations']).to be_an(Array)
      titles = json_response['data']['conversations'].map { |c| c['title'] }
      expect(titles).to include('Urgent Billing Issue')
    end

    it 'respects type filter for messages only' do
      get '/v1/search', params: { q: 'refund', type: 'messages' }, headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['conversations']).to be_empty
      expect(json_response['data']['messages']).not_to be_empty
    end
  end

  describe 'GET /v1/search/suggestions' do
    it 'returns quick typeahead suggestions' do
      get '/v1/search/suggestions', params: { q: 'CONV' }, headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['conversations']).to be_an(Array)
      identifiers = json_response['data']['conversations'].map { |c| c['identifier'] }
      expect(identifiers).to include('CONV-101')
    end
  end
end
