# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::CustomAttributes', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:custom_field) do
    account.with_shard do
      create(:custom_field, account: account, key: 'priority_tier', entity_type: :customer, field_type: :text)
    end
  end

  describe 'GET /v1/custom_attributes' do
    it 'returns custom attributes for the account' do
      get '/v1/custom_attributes', headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to be_an(Array)
      keys = json_response['data'].map { |cf| cf['key'] }
      expect(keys).to include('priority_tier')
    end
  end
end
