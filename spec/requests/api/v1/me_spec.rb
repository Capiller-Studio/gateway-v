# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Me', type: :request do
  let!(:user) { create(:user, email: 'agent@example.com', confirmed_at: Time.current) }
  let!(:account1) { create(:account, name: 'Primary Account') }
  let!(:account2) { create(:account, name: 'Secondary Account') }
  let!(:account_user1) { create(:account_user, account: account1, user: user, owner: true) }
  let!(:account_user2) { create(:account_user, account: account2, user: user, owner: false) }

  describe 'GET /v1/me' do
    context 'with valid JWT authentication' do
      it 'returns user profile, accounts list, and current_account with connection_token' do
        get '/v1/me', headers: auth_headers(user, account: account1)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['user']['id']).to eq(user.id)
        expect(json_response['data']['user']['email']).to eq('agent@example.com')
        expect(json_response['data']['user']['connection_token']).to eq(user.connection_token)
        expect(json_response['data']['accounts'].size).to eq(2)
        expect(json_response['data']['current_account']['id']).to eq(account1.id)
      end

      it 'switches current_account when X-Account-Id header is provided' do
        get '/v1/me', headers: auth_headers(user, account: account2)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['current_account']['id']).to eq(account2.id)
        expect(json_response['data']['current_account']['name']).to eq('Secondary Account')
      end
    end

    describe 'GET /v1/me/cable_token' do
      it 'returns connection_token and ActionCable URL' do
        get '/v1/me/cable_token', headers: auth_headers(user, account: account1)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['connection_token']).to eq(user.connection_token)
        expect(json_response['data']['action_cable_url']).to be_present
        expect(json_response['data']['channels']).to be_an(Array)
      end
    end

    context 'with valid API key authentication' do
      let!(:access_token) { create(:access_token, owner: user, token: 'desk_api_key_123', token_type: :api_key, valid_till: 30.days.from_now) }

      it 'authenticates user via X-Api-Key header' do
        get '/v1/me', headers: { 'X-Api-Key' => 'desk_api_key_123' }

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['user']['id']).to eq(user.id)
      end

      it 'returns 401 when API key is expired' do
        access_token.update!(valid_till: 1.day.ago)

        get '/v1/me', headers: { 'X-Api-Key' => 'desk_api_key_123' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors'].first['code']).to eq('unauthorized')
      end
    end

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get '/v1/me'

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors'].first['code']).to eq('unauthorized')
      end
    end

    context 'with invalid or expired JWT token' do
      it 'returns 401 for tampered JWT' do
        get '/v1/me', headers: { 'Authorization' => 'Bearer invalid_jwt_token' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors'].first['code']).to eq('unauthorized')
      end

      it 'returns 401 for expired JWT' do
        token = JwtService.encode({ user_id: user.id }, expiry: 1.minute)
        Timecop.travel(5.minutes.from_now) do
          get '/v1/me', headers: { 'Authorization' => "Bearer #{token}" }

          expect(response).to have_http_status(:unauthorized)
          expect(json_response['errors'].first['code']).to eq('unauthorized')
        end
      end
    end
  end
end
