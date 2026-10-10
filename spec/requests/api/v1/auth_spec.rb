# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Auth', type: :request do
  let!(:user) { create(:user, email: 'agent@example.com', password: 'Password123!', password_confirmation: 'Password123!', confirmed_at: Time.current) }
  let!(:account) { create(:account, name: 'Acme Corp') }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  describe 'POST /v1/auth/login' do
    context 'with valid credentials' do
      it 'authenticates user and returns JWT token, user, and account context' do
        post '/v1/auth/login', params: { email: 'agent@example.com', password: 'Password123!' }

        expect(response).to have_http_status(:ok)
        expect(json_response['success']).to be true
        expect(json_response['data']['token']).to be_present
        expect(json_response['data']['user']['id']).to eq(user.id)
        expect(json_response['data']['account']['id']).to eq(account.id)

        decoded = JwtService.decode(json_response['data']['token'])
        expect(decoded[:user_id]).to eq(user.id)
        expect(decoded[:account_id]).to eq(account.id)
      end
    end

    context 'with invalid credentials' do
      it 'returns 401 unauthorized for wrong password' do
        post '/v1/auth/login', params: { email: 'agent@example.com', password: 'WrongPassword!' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['success']).to be false
        expect(json_response['errors'].first['code']).to eq('invalid_credentials')
      end

      it 'returns 401 unauthorized for non-existent email' do
        post '/v1/auth/login', params: { email: 'nobody@example.com', password: 'Password123!' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['success']).to be false
        expect(json_response['errors'].first['code']).to eq('invalid_credentials')
      end

      it 'returns 422 for malformed email' do
        post '/v1/auth/login', params: { email: 'not-an-email', password: 'Password123!' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['success']).to be false
      end

      it 'returns 422 when password is missing' do
        post '/v1/auth/login', params: { email: 'agent@example.com' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['success']).to be false
      end

      it 'returns 422 when email is missing' do
        post '/v1/auth/login', params: { password: 'Password123!' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['success']).to be false
      end
    end
  end

  describe 'DELETE /v1/auth/logout' do
    it 'returns success message when authenticated' do
      delete '/v1/auth/logout', headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['message']).to eq('Logged out successfully')
    end

    it 'returns 401 when unauthenticated' do
      delete '/v1/auth/logout'

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['success']).to be false
    end
  end

  describe 'POST /v1/auth/refresh' do
    it 'issues a refreshed JWT token when authenticated' do
      post '/v1/auth/refresh', headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['token']).to be_present

      decoded = JwtService.decode(json_response['data']['token'])
      expect(decoded[:user_id]).to eq(user.id)
    end

    it 'returns 401 when unauthenticated' do
      post '/v1/auth/refresh'

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /v1/auth/register' do
    let(:valid_params) do
      {
        email: 'newuser@example.com',
        password: 'SecurePassword123!',
        first_name: 'Jane',
        last_name: 'Doe',
        account_name: 'Jane Company'
      }
    end

    it 'rejects requests without mobile app secret' do
      post '/v1/auth/register', params: valid_params

      expect(response).to have_http_status(:forbidden)
      expect(json_response['success']).to be false
    end

    it 'registers a new user and account with mobile app secret' do
      post '/v1/auth/register', params: valid_params, headers: mobile_headers

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['token']).to be_present
      expect(json_response['data']['user']['email']).to eq('newuser@example.com')
      expect(json_response['data']['account']['name']).to eq('Jane Company')
    end

    it 'creates an affiliate profile when as_affiliate is true' do
      post '/v1/auth/register', params: valid_params.merge(as_affiliate: true), headers: mobile_headers

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['user']['affiliate_profile']).to be_present
    end

    it 'returns 422 when email is already taken' do
      create(:user, email: 'newuser@example.com')

      post '/v1/auth/register', params: valid_params, headers: mobile_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['success']).to be false
    end

    it 'returns 422 when password is too weak' do
      post '/v1/auth/register', params: valid_params.merge(password: 'weak'), headers: mobile_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['success']).to be false
    end
  end

  describe 'POST /v1/auth/password/forgot and /reset' do
    it 'sends reset instructions for existing email' do
      post '/v1/auth/password/forgot', params: { email: user.email }

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(json_response['success']).to be true
    end

    it 'returns success even for non-existent email to prevent account enumeration' do
      post '/v1/auth/password/forgot', params: { email: 'nonexistent@example.com' }

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(json_response['success']).to be true
    end

    it 'resets password when given valid token and matching confirmation' do
      raw_token = user.send_reset_password_instructions

      post '/v1/auth/password/reset', params: {
        reset_password_token: raw_token,
        password: 'BrandNewPassword123!',
        password_confirmation: 'BrandNewPassword123!'
      }

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(user.reload.valid_password?('BrandNewPassword123!')).to be true
    end

    it 'rejects mismatched password confirmation' do
      raw_token = user.send_reset_password_instructions

      post '/v1/auth/password/reset', params: {
        reset_password_token: raw_token,
        password: 'BrandNewPassword123!',
        password_confirmation: 'DifferentPassword123!'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['success']).to be false
      expect(json_response['errors'].first['field']).to eq('password_confirmation')
    end

    it 'rejects invalid reset token' do
      post '/v1/auth/password/reset', params: {
        reset_password_token: 'invalid_token_123',
        password: 'NewPassword123!',
        password_confirmation: 'NewPassword123!'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['success']).to be false
    end
  end

  describe 'Enhanced /v1/me endpoints' do
    let!(:second_account) { create(:account, name: 'Second Company') }
    let!(:second_membership) { create(:account_user, account: second_account, user: user, owner: false) }
    let!(:foreign_account) { create(:account, name: 'Foreign Company') }

    it 'returns user profile, roles, and accounts' do
      get '/v1/me', headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['user']['id']).to eq(user.id)
      expect(json_response['data']['accounts'].size).to eq(2)
      expect(json_response['data']['current_account']['id']).to eq(account.id)
    end

    it 'updates profile information' do
      patch '/v1/me/profile', params: { first_name: 'UpdatedName' }, headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['first_name']).to eq('UpdatedName')
    end

    it 'updates availability status' do
      patch '/v1/me/availability', params: { availability: 'offline' }, headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['availability']).to eq('offline')
    end

    it 'switches active account successfully' do
      post "/v1/me/switch_account/#{second_account.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['token']).to be_present
      expect(json_response['data']['account']['id']).to eq(second_account.id)

      decoded = JwtService.decode(json_response['data']['token'])
      expect(decoded[:account_id]).to eq(second_account.id)
    end

    it 'prevents switching to foreign unauthorized account' do
      post "/v1/me/switch_account/#{foreign_account.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:forbidden)
      expect(json_response['success']).to be false
    end
  end
end
