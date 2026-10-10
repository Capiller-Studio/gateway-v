# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::CustomFields', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:custom_field) do
    account.with_shard do
      create(:custom_field,
             account: account,
             key: 'account_tier',
             entity_type: :customer,
             field_type: :text,
             label: 'Account Tier')
    end
  end

  describe 'GET /v1/custom_fields' do
    it 'returns list of custom field definitions' do
      get '/v1/custom_fields', headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to be >= 1
      keys = json_response['data'].map { |f| f['key'] }
      expect(keys).to include('account_tier')
    end

    it 'filters by entity_type' do
      get '/v1/custom_fields', params: { entity_type: 'customer' }, headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['data'].all? { |f| f['entity_type'] == 'customer' }).to be true
      keys = json_response['data'].map { |f| f['key'] }
      expect(keys).to include('account_tier')

      get '/v1/custom_fields', params: { entity_type: 'conversation' }, headers: auth_headers(user, account: account)
      expect(response).to have_http_status(:ok)
      expect(json_response['data'].all? { |f| f['entity_type'] == 'conversation' }).to be true
    end
  end

  describe 'POST /v1/custom_fields' do
    it 'creates a new custom field definition' do
      post '/v1/custom_fields',
           params: {
             key: 'plan_type',
             label: 'Plan Type',
             entity_type: 'customer',
             field_type: 'select',
             options: %w[starter pro enterprise],
             required: true
           },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:created)
      expect(json_response['success']).to be true
      expect(json_response['data']['key']).to eq('plan_type')
      expect(json_response['data']['required']).to be true
    end
  end

  describe 'GET /v1/custom_fields/:id' do
    it 'returns field details' do
      get "/v1/custom_fields/#{custom_field.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['id']).to eq(custom_field.id)
      expect(json_response['data']['key']).to eq('account_tier')
    end
  end

  describe 'PATCH /v1/custom_fields/:id' do
    it 'updates field properties' do
      patch "/v1/custom_fields/#{custom_field.id}",
            params: { label: 'Customer Tier Level', required: true },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['label']).to eq('Customer Tier Level')
      expect(json_response['data']['required']).to be true
    end
  end

  describe 'DELETE /v1/custom_fields/:id' do
    it 'deletes a custom field definition' do
      delete "/v1/custom_fields/#{custom_field.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(account.with_shard { CustomField.find_by(id: custom_field.id) }).to be_nil
    end
  end
end
