# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Sessions', type: :request do
  let!(:user) { create(:user, email: 'agent@example.com', password: 'Password123!', password_confirmation: 'Password123!', confirmed_at: Time.current) }

  describe 'POST /api/v1/sessions' do
    context 'with valid credentials' do
      it 'authenticates user and returns JWT token and user entity' do
        post '/v1/sessions', params: { email: 'agent@example.com', password: 'Password123!' }

        expect(response).to have_http_status(:created).or have_http_status(:ok)
        expect(json_response).to have_key('data')
        expect(json_response['data']['token']).to be_present

        # Verify decoded token
        payload = JwtService.decode(json_response['data']['token'])
        expect(payload[:user_id]).to eq(user.id)

        # Verify user data
        expect(json_response['data']['user']['id']).to eq(user.id)
        expect(json_response['data']['user']['email']).to eq('agent@example.com')
      end
    end

    context 'with invalid password' do
      it 'returns 401 unauthorized with invalid_credentials error' do
        post '/v1/sessions', params: { email: 'agent@example.com', password: 'WrongPassword!' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors']).to be_an(Array)
        expect(json_response['errors'].first['code']).to eq('invalid_credentials')
      end
    end

    context 'with non-existent email' do
      it 'returns 401 unauthorized with invalid_credentials error' do
        post '/v1/sessions', params: { email: 'unknown@example.com', password: 'Password123!' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors']).to be_an(Array)
        expect(json_response['errors'].first['code']).to eq('invalid_credentials')
      end
    end

    context 'with invalid email format' do
      it 'returns 422 validation error' do
        post '/v1/sessions', params: { email: 'invalid-email-format', password: 'Password123!' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to be_an(Array)
        expect(json_response['errors'].first['field']).to eq('email')
      end
    end

    context 'with missing required parameters' do
      it 'returns 422 when password is missing' do
        post '/v1/sessions', params: { email: 'agent@example.com' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to be_an(Array)
        expect(json_response['errors'].first['field']).to eq('password')
      end

      it 'returns 422 when email is missing' do
        post '/v1/sessions', params: { password: 'Password123!' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to be_an(Array)
        expect(json_response['errors'].first['field']).to eq('email')
      end
    end
  end
end
