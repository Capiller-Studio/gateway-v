# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Conversations Advanced & AI', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:inbox) { account.with_shard { create(:inbox, account: account) } }
  let!(:customer) { account.with_shard { create(:customer, account: account) } }

  let!(:conv1) do
    account.with_shard do
      c = create(:conversation, account: account, inbox: inbox, status: :active, priority: :medium)
      c.conversation_members.create!(member: customer, account: account)
      c
    end
  end

  let!(:conv2) do
    account.with_shard do
      c = create(:conversation, account: account, inbox: inbox, status: :active, priority: :high)
      c.conversation_members.create!(member: customer, account: account)
      c
    end
  end

  describe 'Bulk Actions' do
    it 'bulk resolves multiple conversations' do
      post '/v1/conversations/bulk_action',
           params: { conversation_ids: [conv1.id, conv2.id], action: 'resolve' },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['updated_count']).to eq(2)
      expect(conv1.reload.status).to eq('resolved')
      expect(conv2.reload.status).to eq('resolved')
    end

    it 'bulk reopens multiple conversations' do
      account.with_shard { conv1.update!(status: :resolved) }

      post '/v1/conversations/bulk_action',
           params: { conversation_ids: [conv1.id], action: 'reopen' },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(conv1.reload.status).to eq('active')
    end
  end

  describe 'Conversation Reopen and Read' do
    it 'reopens a resolved conversation' do
      account.with_shard { conv1.update!(status: :resolved) }

      post "/v1/conversations/#{conv1.id}/reopen", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['status']).to eq('active')
    end

    it 'marks conversation as read' do
      post "/v1/conversations/#{conv1.id}/read", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['read']).to be true
    end
  end

  describe 'Conversation AI Subresource' do
    it 'returns AI summary for conversation' do
      post "/v1/conversations/#{conv1.id}/ai/summarize", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['summary']).to be_present
    end

    it 'generates AI draft reply' do
      post "/v1/conversations/#{conv1.id}/ai/draft_reply",
           params: { instruction: 'Be polite' },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['draft']).to be_present
    end

    it 'rewrites tone using AI' do
      post "/v1/conversations/#{conv1.id}/ai/rewrite_tone",
           params: { text: 'hey look into this', tone: 'formal' },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['tone']).to eq('formal')
    end

    it 'fixes grammar using AI' do
      post "/v1/conversations/#{conv1.id}/ai/fix_grammar",
           params: { text: 'we is working on this' },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
    end

    it 'translates conversation' do
      post "/v1/conversations/#{conv1.id}/ai/translate",
           params: { target_locale: 'es' },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['target_locale']).to eq('es')
    end
  end
end
