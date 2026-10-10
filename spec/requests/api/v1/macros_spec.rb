# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Macros', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }

  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:inbox) { account.with_shard { create(:inbox, account: account) } }
  let!(:conversation) { account.with_shard { create(:conversation, account: account, inbox: inbox, status: :active) } }

  let!(:macro) do
    account.with_shard do
      create(:macro,
             account: account,
             name: 'Close and Resolve',
             visibility: :account_wide,
             actions: [{ 'action' => 'set_status', 'params' => { 'status' => 'resolved' } }])
    end
  end

  describe 'GET /v1/macros' do
    it 'returns list of visible macros' do
      get '/v1/macros', headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to eq(1)
      expect(json_response['data'].first['name']).to eq('Close and Resolve')
      expect(json_response['data'].first['action_names']).to eq(['set_status'])
    end
  end

  describe 'POST /v1/macros' do
    it 'creates a new macro' do
      post '/v1/macros',
           params: {
             name: 'Escalate to Urgent',
             description: 'Sets priority to urgent',
             actions: [{ 'action' => 'set_priority', 'params' => { 'priority' => 'urgent' } }],
             visibility: 'account_wide'
           },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:created)
      expect(json_response['success']).to be true
      expect(json_response['data']['name']).to eq('Escalate to Urgent')
    end
  end

  describe 'GET /v1/macros/:id' do
    it 'returns macro details' do
      get "/v1/macros/#{macro.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['id']).to eq(macro.id)
    end
  end

  describe 'PATCH /v1/macros/:id' do
    it 'updates macro properties' do
      patch "/v1/macros/#{macro.id}",
            params: { name: 'Renamed Macro', description: 'Updated info' },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['name']).to eq('Renamed Macro')
    end
  end

  describe 'DELETE /v1/macros/:id' do
    it 'deletes a macro' do
      delete "/v1/macros/#{macro.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(account.with_shard { Macro.find_by(id: macro.id) }).to be_nil
    end
  end

  describe 'POST /v1/macros/:id/execute' do
    it 'executes the macro actions on the conversation' do
      post "/v1/macros/#{macro.id}/execute",
           params: { conversation_id: conversation.id },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['status']).to eq('success')
      expect(conversation.reload.status).to eq('resolved')
    end
  end
end
