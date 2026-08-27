# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API Key Authentication & Plan Feature Gating', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:api_token) do
    AccessToken.create!(
      owner: account,
      token_type: :api_key,
      token: "desk_key_#{SecureRandom.hex(16)}"
    )
  end

  describe 'GET /v1/inboxes with API Key' do
    context 'when plan allows API Channel access' do
      it 'authenticates successfully and returns inboxes' do
        get '/v1/inboxes', headers: { 'X-Api-Key' => api_token.token }

        expect(response).to have_http_status(:ok)
        expect(json_response['data']).to be_an(Array)
      end
    end

    context 'when plan does not allow API Channel access' do
      it 'returns 403 forbidden' do
        plan.update!(features: { 'channels' => { 'api' => false }, 'api_access' => false })

        get '/v1/inboxes', headers: { 'X-Api-Key' => api_token.token }

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('forbidden')
      end
    end

    context 'when API key is expired' do
      let!(:expired_token) do
        AccessToken.create!(
          owner: account,
          token_type: :api_key,
          token: "expired_key_#{SecureRandom.hex(16)}",
          valid_till: 1.day.ago
        )
      end

      it 'returns 401 unauthorized' do
        get '/v1/inboxes', headers: { 'X-Api-Key' => expired_token.token }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
