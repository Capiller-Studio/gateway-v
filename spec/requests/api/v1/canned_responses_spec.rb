# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::CannedResponses', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:canned_greet) do
    account.with_shard do
      account.canned_responses.create!(
        name: 'Greeting Template',
        description: 'Hello! How may I assist you today?',
        identifier: 'GREET'
      )
    end
  end

  let!(:canned_closing) do
    account.with_shard do
      account.canned_responses.create!(
        name: 'Closing Note',
        description: 'Thank you for reaching out to us.',
        identifier: 'BYE'
      )
    end
  end

  describe 'GET /v1/canned_responses' do
    context 'when authenticated with active subscription' do
      it 'returns list of canned responses' do
        get '/v1/canned_responses', headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(2)
        expect(json_response['data'].map { |cr| cr['identifier'] }).to include('GREET', 'BYE')
      end

      it 'searches canned responses by query' do
        get '/v1/canned_responses', params: { search: 'Greeting' }, headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(1)
        expect(json_response['data'].first['name']).to eq('Greeting Template')
      end
    end

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get '/v1/canned_responses'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
