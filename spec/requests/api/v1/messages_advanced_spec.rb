# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Messages Advanced (Cursor & Reactions)', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:inbox) { account.with_shard { create(:inbox, account: account) } }
  let!(:conversation) { account.with_shard { create(:conversation, account: account, inbox: inbox) } }

  let!(:msg1) do
    account.with_shard do
      create(:message, account: account, conversation: conversation, sender: user, content: 'First message', created_at: 3.hours.ago)
    end
  end

  let!(:msg2) do
    account.with_shard do
      create(:message, account: account, conversation: conversation, sender: user, content: 'Second message', created_at: 2.hours.ago)
    end
  end

  let!(:msg3) do
    account.with_shard do
      create(:message, account: account, conversation: conversation, sender: user, content: 'Third message', created_at: 1.hour.ago)
    end
  end

  describe 'Cursor-Based Pagination' do
    it 'supports before_id cursor to fetch older messages' do
      get "/v1/conversations/#{conversation.id}/messages",
          params: { before_id: msg3.id, limit: 1 },
          headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to eq(1)
      expect(json_response['data'].first['id']).to eq(msg1.id)
      expect(json_response['meta']['pagination']['before_id']).to be_present
    end

    it 'supports after_id cursor to fetch newer messages' do
      get "/v1/conversations/#{conversation.id}/messages",
          params: { after_id: msg1.id, limit: 1 },
          headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to eq(1)
      expect(json_response['data'].first['id']).to eq(msg2.id)
    end
  end

  describe 'Standalone Message Endpoints & Reactions' do
    it 'fetches a single message by ID' do
      get "/v1/messages/#{msg1.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['id']).to eq(msg1.id)
      expect(json_response['data']['content']).to eq('First message')
    end

    it 'adds and removes emoji reactions' do
      # Add reaction
      post "/v1/messages/#{msg2.id}/reactions",
           params: { emoji: '👍' },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['emoji']).to eq('👍')

      # Verify reaction present in message entity
      get "/v1/messages/#{msg2.id}", headers: auth_headers(user, account: account)
      expect(json_response['data']['reactions']).to be_an(Array)
      expect(json_response['data']['reactions'].first['emoji']).to eq('👍')

      # Remove reaction via URL-encoded path
      delete "/v1/messages/#{msg2.id}/reactions/#{CGI.escape('👍')}", headers: auth_headers(user, account: account)
      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true

      # Verify reaction removed
      get "/v1/messages/#{msg2.id}", headers: auth_headers(user, account: account)
      expect(json_response['data']['reactions']).to be_empty

      # Add reaction again and remove via query param
      post "/v1/messages/#{msg2.id}/reactions",
           params: { emoji: '🔥' },
           headers: auth_headers(user, account: account)
      expect(response).to have_http_status(:created).or have_http_status(:ok)

      delete "/v1/messages/#{msg2.id}/reactions",
             params: { emoji: '🔥' },
             headers: auth_headers(user, account: account)
      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
    end
  end
end
