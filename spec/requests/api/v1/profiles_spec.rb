# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Profiles', type: :request do
  let!(:account) { create(:account, name: 'Main HQ') }
  let!(:user) { create(:user, first_name: 'John', last_name: 'Doe', email: 'john.doe@example.com', password: 'Password123!', password_confirmation: 'Password123!', confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true, availability: :online) }

  describe 'GET /v1/profile' do
    context 'when authenticated' do
      it 'returns user profile, current account, and availability' do
        get '/v1/profile', headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['user']['email']).to eq('john.doe@example.com')
        expect(json_response['data']['current_account']['name']).to eq('Main HQ')
        expect(json_response['data']['availability']).to eq('online')
      end
    end

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get '/v1/profile'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /v1/profile' do
    context 'when updating profile details' do
      it 'updates first_name, last_name, and display_name' do
        patch '/v1/profile',
              params: { first_name: 'Jane', last_name: 'Smith', display_name: 'Jane S.' },
              headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(user.reload.first_name).to eq('Jane')
        expect(user.last_name).to eq('Smith')
        expect(user.display_name).to eq('Jane Smith')
      end
    end

    context 'when updating password' do
      it 'updates password when current password matches' do
        patch '/v1/profile',
              params: {
                current_password: 'Password123!',
                password: 'NewSecurePassword123!',
                password_confirmation: 'NewSecurePassword123!'
              },
              headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(user.reload.valid_password?('NewSecurePassword123!')).to be true
      end

      it 'returns 422 when current password is invalid' do
        patch '/v1/profile',
              params: {
                current_password: 'WrongPassword!',
                password: 'NewSecurePassword123!',
                password_confirmation: 'NewSecurePassword123!'
              },
              headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors'].first['field']).to eq('current_password')
      end

      it 'returns 422 when password confirmation does not match' do
        patch '/v1/profile',
              params: {
                current_password: 'Password123!',
                password: 'NewSecurePassword123!',
                password_confirmation: 'MismatchPassword123!'
              },
              headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors'].first['field']).to eq('password_confirmation')
      end
    end
  end

  describe 'PATCH /v1/profile/availability' do
    it 'toggles agent availability status to offline' do
      patch '/v1/profile/availability',
            params: { availability: 'offline' },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['availability']).to eq('offline')
      expect(account_user.reload.availability).to eq('offline')
      expect(account_user.availability_changed_at).to be_present
    end

    it 'returns 422 for invalid availability value' do
      patch '/v1/profile/availability',
            params: { availability: 'invalid_status' },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
