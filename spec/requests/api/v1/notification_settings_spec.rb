# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::NotificationSettings', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  describe 'GET /v1/notification_settings' do
    it 'returns 401 when unauthenticated' do
      get '/v1/notification_settings'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns current user notification settings' do
      get '/v1/notification_settings', headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to be_a(Hash)
      expect(json_response['data']).to have_key('email_conversation_created')
      expect(json_response['data']).to have_key('push_conversation_created')
    end
  end

  describe 'PATCH /v1/notification_settings' do
    it 'updates delivery preferences' do
      patch '/v1/notification_settings',
            params: {
              email_conversation_created: false,
              push_conversation_created: true,
              email_sla_breached: true
            },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['email_conversation_created']).to eq(false)
      expect(json_response['data']['push_conversation_created']).to eq(true)
      expect(json_response['data']['email_sla_breached']).to eq(true)
    end
  end
end
