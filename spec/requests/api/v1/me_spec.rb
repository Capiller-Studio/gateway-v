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

  describe 'PATCH /v1/me/profile' do
    let!(:user_with_pw) { create(:user, first_name: 'John', last_name: 'Doe', email: 'john.profile@example.com', password: 'Password123!', password_confirmation: 'Password123!', confirmed_at: Time.current) }
    let!(:pw_account) { create(:account, name: 'Profile Corp') }
    let!(:pw_account_user) { create(:account_user, account: pw_account, user: user_with_pw, owner: true) }

    context 'when updating profile details' do
      it 'updates first_name, last_name, and display_name' do
        patch '/v1/me/profile',
              params: { first_name: 'Jane', last_name: 'Smith', display_name: 'Jane S.' },
              headers: auth_headers(user_with_pw, account: pw_account)

        expect(response).to have_http_status(:ok)
        expect(json_response['success']).to be true
        expect(user_with_pw.reload.first_name).to eq('Jane')
        expect(user_with_pw.last_name).to eq('Smith')
        expect(user_with_pw.display_name).to eq('Jane Smith')
      end
    end

    context 'when updating password' do
      it 'updates password when current password matches' do
        patch '/v1/me/profile',
              params: {
                current_password: 'Password123!',
                password: 'NewSecurePassword123!',
                password_confirmation: 'NewSecurePassword123!'
              },
              headers: auth_headers(user_with_pw, account: pw_account)

        expect(response).to have_http_status(:ok)
        expect(json_response['success']).to be true
        expect(user_with_pw.reload.valid_password?('NewSecurePassword123!')).to be true
      end

      it 'returns 422 when current password is blank or incorrect' do
        patch '/v1/me/profile',
              params: {
                current_password: 'WrongPassword!',
                password: 'NewSecurePassword123!',
                password_confirmation: 'NewSecurePassword123!'
              },
              headers: auth_headers(user_with_pw, account: pw_account)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['success']).to be false
        expect(json_response['errors'].first['field']).to eq('current_password')
      end

      it 'returns 422 when password confirmation mismatches' do
        patch '/v1/me/profile',
              params: {
                current_password: 'Password123!',
                password: 'NewSecurePassword123!',
                password_confirmation: 'MismatchPassword123!'
              },
              headers: auth_headers(user_with_pw, account: pw_account)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['success']).to be false
        expect(json_response['errors'].first['field']).to eq('password_confirmation')
      end
    end
  end

  describe 'PATCH /v1/me/availability' do
    it 'toggles agent availability status to offline' do
      patch '/v1/me/availability',
            params: { availability: 'offline' },
            headers: auth_headers(user, account: account1)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['availability']).to eq('offline')
      expect(account_user1.reload.availability).to eq('offline')
      expect(account_user1.availability_changed_at).to be_present
    end

    it 'returns 422 for invalid availability value' do
      patch '/v1/me/availability',
            params: { availability: 'invalid_status' },
            headers: auth_headers(user, account: account1)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['success']).to be false
    end
  end

  describe 'POST /v1/me/switch_account/:account_id' do
    let!(:unauthorized_account) { create(:account, name: 'Secret Org') }

    it 'switches active account and returns new JWT token' do
      post "/v1/me/switch_account/#{account2.id}", headers: auth_headers(user, account: account1)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['token']).to be_present
      expect(json_response['data']['account']['id']).to eq(account2.id)

      decoded = JwtService.decode(json_response['data']['token'])
      expect(decoded[:account_id]).to eq(account2.id)
    end

    it 'returns 403 when user is not a member of target account' do
      post "/v1/me/switch_account/#{unauthorized_account.id}", headers: auth_headers(user, account: account1)

      expect(response).to have_http_status(:forbidden)
      expect(json_response['success']).to be false
      expect(json_response['errors'].first['code']).to eq('forbidden')
    end
  end
end
