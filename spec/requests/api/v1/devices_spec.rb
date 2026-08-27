# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Devices', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  describe 'POST /v1/devices' do
    let(:valid_params) do
      {
        token: 'fcm-device-token-123456',
        platform: 'ios',
        name: "Ahsan's iPhone 16 Pro"
      }
    end

    context 'when authenticated' do
      it 'registers device token for the current user' do
        expect do
          post '/v1/devices', params: valid_params, headers: auth_headers(user, account: account)
        end.to change { account.with_shard { user.notification_subscriptions.count } }.by(1)

        expect(response).to have_http_status(:created).or have_http_status(:ok)
        expect(json_response['data']['token']).to eq('fcm-device-token-123456')
        expect(json_response['data']['platform']).to eq('ios')
        expect(json_response['data']['name']).to eq("Ahsan's iPhone 16 Pro")
      end

      it 'updates existing device token idempotently' do
        post '/v1/devices', params: valid_params, headers: auth_headers(user, account: account)

        expect do
          post '/v1/devices', params: valid_params.merge(name: 'Updated Device Name'), headers: auth_headers(user, account: account)
        end.not_to change { account.with_shard { user.notification_subscriptions.count } }

        expect(response).to have_http_status(:created).or have_http_status(:ok)
        expect(json_response['data']['name']).to eq('Updated Device Name')
      end

      it 'returns 422 when token is missing' do
        post '/v1/devices', params: { platform: 'ios' }, headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors'].first['field']).to eq('token')
      end
    end

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        post '/v1/devices', params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /v1/devices/:token' do
    let!(:subscription) do
      account.with_shard do
        user.notification_subscriptions.create!(
          subscription_type: :fcm,
          name: "Ahsan's iPhone",
          data: { 'device_token' => 'fcm-device-token-123456', 'platform' => 'ios' }
        )
      end
    end

    context 'when authenticated' do
      it 'unregisters the device token' do
        expect do
          delete '/v1/devices/fcm-device-token-123456', headers: auth_headers(user, account: account)
        end.to change { account.with_shard { user.notification_subscriptions.count } }.by(-1)

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Device unregistered successfully')
      end
    end

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        delete '/v1/devices/fcm-device-token-123456'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
