# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Labels', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:label_billing) do
    account.with_shard do
      account.labels.create!(title: 'Billing Inquiry', color: '#EF4444')
    end
  end

  describe 'GET /v1/labels' do
    context 'when authenticated with active subscription' do
      it 'returns list of labels' do
        get '/v1/labels', headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(1)
        expect(json_response['data'].first['title']).to eq('Billing Inquiry')
      end
    end

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get '/v1/labels'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /v1/labels' do
    context 'when authenticated with write permission' do
      it 'creates a new label' do
        expect do
          post '/v1/labels',
               params: { title: 'Bug Report', color: '#F59E0B', description: 'User encountered a bug' },
               headers: auth_headers(user, account: account)
        end.to change { account.with_shard { account.labels.count } }.by(1)

        expect(response).to have_http_status(:created).or have_http_status(:ok)
        expect(json_response['data']['title']).to eq('Bug Report')
        expect(json_response['data']['color']).to eq('#F59E0B')
      end

      it 'returns 422 when title is blank' do
        post '/v1/labels', params: { title: '' }, headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors'].first['field']).to eq('title')
      end
    end
  end
end
