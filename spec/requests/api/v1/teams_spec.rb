# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Teams', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:team_sales) do
    account.with_shard do
      account.teams.create!(name: 'Sales Support', description: 'Handles sales queries')
    end
  end

  let!(:team_tech) do
    account.with_shard do
      account.teams.create!(name: 'Technical Support', description: 'Handles tier 2 bugs')
    end
  end

  describe 'GET /v1/teams' do
    context 'when authenticated with active subscription' do
      it 'returns list of teams in the account' do
        get '/v1/teams', headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(2)
        expect(json_response['data'].map { |t| t['name'] }).to include('Sales Support', 'Technical Support')
      end

      it 'respects pagination' do
        get '/v1/teams', params: { per_page: 1 }, headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(1)
        expect(json_response['meta']['total_count']).to eq(2)
      end
    end

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get '/v1/teams'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
