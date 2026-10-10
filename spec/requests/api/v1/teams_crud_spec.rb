# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Teams CRUD & Members', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:agent1) { create(:user, confirmed_at: Time.current) }
  let!(:agent2) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:account_agent1) { create(:account_user, account: account, user: agent1) }
  let!(:account_agent2) { create(:account_user, account: account, user: agent2) }

  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:team) { account.with_shard { create(:team, account: account, name: 'Tier 1 Support') } }

  describe 'POST /v1/teams' do
    it 'creates a new team' do
      post '/v1/teams',
           params: {
             name: 'Billing Squad',
             description: 'Handles billing questions',
             auto_assign: true,
             user_ids: [agent1.id]
           },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:created)
      expect(json_response['success']).to be true
      expect(json_response['data']['name']).to eq('Billing Squad')
      expect(json_response['data']['member_count']).to eq(1)
    end
  end

  describe 'GET /v1/teams/:id' do
    it 'returns team details' do
      get "/v1/teams/#{team.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['id']).to eq(team.id)
      expect(json_response['data']['name']).to eq('Tier 1 Support')
    end
  end

  describe 'PATCH /v1/teams/:id' do
    it 'updates team properties' do
      patch "/v1/teams/#{team.id}",
            params: {
              name: 'Tier 1 Elite',
              description: 'Updated description'
            },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['name']).to eq('Tier 1 Elite')
    end
  end

  describe 'DELETE /v1/teams/:id' do
    it 'deletes a team' do
      delete "/v1/teams/#{team.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(account.with_shard { Team.find_by(id: team.id) }).to be_nil
    end
  end

  describe 'Team Members Subresource' do
    it 'adds a member with lead role' do
      post "/v1/teams/#{team.id}/members",
           params: { user_id: agent1.id, role: 'lead' },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:created)
      expect(json_response['success']).to be true
      expect(json_response['data']['role']).to eq('lead')
      expect(json_response['data']['user_id']).to eq(agent1.id)
    end

    it 'lists team members' do
      account.with_shard { team.team_users.create!(user_id: agent1.id, role: :member) }

      get "/v1/teams/#{team.id}/members", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to eq(1)
      expect(json_response['data'].first['user_id']).to eq(agent1.id)
    end

    it 'removes a member from team' do
      account.with_shard { team.team_users.create!(user_id: agent1.id, role: :member) }

      delete "/v1/teams/#{team.id}/members/#{agent1.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(account.with_shard { team.team_users.count }).to eq(0)
    end
  end
end
