# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Passwords', type: :request do
  let!(:user) { create(:user, email: 'alex@example.com', password: 'OldPassword123!', password_confirmation: 'OldPassword123!', confirmed_at: Time.current) }

  describe 'POST /v1/passwords/forgot' do
    it 'sends reset instructions when email exists' do
      expect do
        post '/v1/passwords/forgot', params: { email: 'alex@example.com' }
      end.to change { user.reload.reset_password_sent_at }

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(json_response['message']).to include('instructions')
    end

    it 'returns success message even for non-existent email to prevent enumeration' do
      post '/v1/passwords/forgot', params: { email: 'nobody@example.com' }

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(json_response['message']).to include('instructions')
    end

    it 'returns 422 for invalid email format' do
      post '/v1/passwords/forgot', params: { email: 'invalid-email-format' }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'POST /v1/passwords/reset' do
    let(:raw_token) do
      user.send_reset_password_instructions
    end

    it 'resets password when given valid token and matching confirmation' do
      post '/v1/passwords/reset',
           params: {
             reset_password_token: raw_token,
             password: 'BrandNewPassword123!',
             password_confirmation: 'BrandNewPassword123!'
           }

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(user.reload.valid_password?('BrandNewPassword123!')).to be true
    end

    it 'returns 422 when password confirmation mismatches' do
      post '/v1/passwords/reset',
           params: {
             reset_password_token: raw_token,
             password: 'BrandNewPassword123!',
             password_confirmation: 'DifferentPassword123!'
           }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors'].first['field']).to eq('password_confirmation')
    end

    it 'returns 422 when new password lacks complexity requirements' do
      post '/v1/passwords/reset',
           params: {
             reset_password_token: raw_token,
             password: 'weakpassword',
             password_confirmation: 'weakpassword'
           }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors'].first['field']).to eq('password')
    end

    it 'returns 422 for invalid or expired token' do
      post '/v1/passwords/reset',
           params: {
             reset_password_token: 'invalid_or_expired_token',
             password: 'BrandNewPassword123!',
             password_confirmation: 'BrandNewPassword123!'
           }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
