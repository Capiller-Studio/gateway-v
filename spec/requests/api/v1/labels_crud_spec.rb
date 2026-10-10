# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Labels CRUD Extensions', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:label) { account.with_shard { create(:label, account: account, title: 'VIP Support', color: '#10B981') } }

  describe 'GET /v1/labels/:id' do
    it 'returns label details' do
      get "/v1/labels/#{label.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['id']).to eq(label.id)
      expect(json_response['data']['title']).to eq('VIP Support')
      expect(json_response['data']['color']).to eq('#10B981')
    end
  end

  describe 'PATCH /v1/labels/:id' do
    it 'updates label title and color' do
      patch "/v1/labels/#{label.id}",
            params: { title: 'High Priority VIP', color: '#EF4444' },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['title']).to eq('High Priority VIP')
      expect(json_response['data']['color']).to eq('#EF4444')
    end
  end

  describe 'DELETE /v1/labels/:id' do
    it 'deletes a label' do
      delete "/v1/labels/#{label.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(account.with_shard { Label.find_by(id: label.id) }).to be_nil
    end
  end
end
