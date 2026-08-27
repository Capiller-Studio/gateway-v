# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Registrations', type: :request do
  describe 'POST /v1/registrations' do
    let(:valid_params) do
      {
        email: 'newuser@example.com',
        password: 'Password123!',
        first_name: 'Jane',
        last_name: 'Doe',
        account_name: 'Acme Corp'
      }
    end

    context 'without mobile app secret header' do
      it 'returns 403 forbidden' do
        post '/v1/registrations', params: valid_params

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('forbidden')
      end
    end

    context 'with invalid mobile app secret header' do
      it 'returns 403 forbidden' do
        post '/v1/registrations', params: valid_params, headers: { 'X-Mobile-App-Secret' => 'invalid_secret' }

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('forbidden')
      end
    end

    context 'with valid mobile app secret header' do
      it 'registers user and account with owner role' do
        expect do
          post '/v1/registrations', params: valid_params, headers: mobile_headers
        end.to change(User, :count).by(1).and change(Account, :count).by(1)

        expect(response).to have_http_status(:created).or have_http_status(:ok)
        expect(json_response['data']['token']).to be_present
        expect(json_response['data']['user']['email']).to eq('newuser@example.com')
        expect(json_response['data']['account']['name']).to eq('Acme Corp')

        # Verify owner role assignment
        user = User.find_by(email: 'newuser@example.com')
        account = Account.find_by(name: 'Acme Corp')
        account_user = user.account_users.find_by(account: account)
        expect(account_user.owner).to be true
      end

      it 'creates an affiliate profile when as_affiliate is true' do
        params = valid_params.merge(as_affiliate: true)

        expect do
          post '/v1/registrations', params: params, headers: mobile_headers
        end.to change(User, :count).by(1).and change(Affiliate::Profile, :count).by(1)

        expect(response).to have_http_status(:created).or have_http_status(:ok)
        expect(json_response['data']['user']['affiliate_profile']).to be_present
      end

      it 'returns 422 when email is already taken' do
        create(:user, email: 'newuser@example.com')

        post '/v1/registrations', params: valid_params, headers: mobile_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to be_an(Array)
      end

      it 'returns 422 when password is too short' do
        params = valid_params.merge(password: '123')

        post '/v1/registrations', params: params, headers: mobile_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to be_an(Array)
      end

      it 'returns 422 when password lacks uppercase or special character' do
        params = valid_params.merge(password: 'password123')

        post '/v1/registrations', params: params, headers: mobile_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors'].first['field']).to eq('password')
      end

      it 'returns 422 when email format is invalid' do
        params = valid_params.merge(email: 'invalid_email')

        post '/v1/registrations', params: params, headers: mobile_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to be_an(Array)
      end
    end
  end
end
