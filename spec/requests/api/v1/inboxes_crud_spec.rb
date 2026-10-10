# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Inboxes CRUD & Members', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:agent1) { create(:user, confirmed_at: Time.current) }
  let!(:agent2) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:account_agent1) { create(:account_user, account: account, user: agent1) }
  let!(:account_agent2) { create(:account_user, account: account, user: agent2) }
  let!(:team) { create(:team, account: account, name: 'Tier 1 Support') }

  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:inbox) { account.with_shard { create(:inbox, account: account, name: 'Support Queue') } }

  describe 'GET /v1/inboxes filtering' do
    it 'filters inboxes by supported channel types' do
      get '/v1/inboxes', params: { channel_type: 'custom' }, headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']).to be_an(Array)
    end
  end

  describe 'PATCH /v1/inboxes/:id' do
    it 'updates inbox properties including auto_assign and csat' do
      patch "/v1/inboxes/#{inbox.id}",
            params: {
              name: 'Renamed Support',
              display_name: 'Customer Happiness',
              default_locale: 'en',
              auto_assign: true,
              csat_survey_enabled: true,
              reopen_window_seconds: 3600,
              member_ids: [agent1.id],
              team_ids: [team.id]
            },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['name']).to eq('Renamed Support')
      expect(json_response['data']['display_name']).to eq('Customer Happiness')
      expect(json_response['data']['auto_assign']).to be true
      expect(json_response['data']['csat_survey_enabled']).to be true
      expect(json_response['data']['member_ids']).to include(agent1.id)
      expect(json_response['data']['team_ids']).to include(team.id)
    end
  end

  describe 'DELETE /v1/inboxes/:id' do
    it 'destroys an inbox' do
      delete "/v1/inboxes/#{inbox.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(account.with_shard { Inbox.find_by(id: inbox.id) }).to be_nil
    end
  end

  describe 'Inbox Members Subresource' do
    before do
      account.with_shard { inbox.assign_users([agent1.id]) }
    end

    it 'lists assigned members' do
      get "/v1/inboxes/#{inbox.id}/members", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to eq(1)
      expect(json_response['data'].first['id']).to eq(agent1.id)
    end

    it 'adds members to inbox' do
      post "/v1/inboxes/#{inbox.id}/members",
           params: { user_ids: [agent2.id] },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['member_ids']).to include(agent1.id, agent2.id)
    end

    it 'removes a member from inbox' do
      delete "/v1/inboxes/#{inbox.id}/members/#{agent1.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(account.with_shard { inbox.reload.assigned_user_ids }).to be_empty
    end
  end
end
