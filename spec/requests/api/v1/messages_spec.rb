# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Messages', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:inbox) { account.with_shard { create(:inbox, account: account) } }
  let!(:customer) { account.with_shard { create(:customer, account: account) } }
  let!(:conversation) do
    account.with_shard do
      conv = create(:conversation, account: account, inbox: inbox)
      conv.conversation_members.create!(member: customer, account: account)
      conv
    end
  end

  let!(:message1) do
    account.with_shard do
      create(:message, account: account, conversation: conversation, inbox: inbox, sender: customer, content: 'Hello support team')
    end
  end

  let!(:message2) do
    account.with_shard do
      create(:message, account: account, conversation: conversation, inbox: inbox, sender: user, content: 'Hi! How can I help?')
    end
  end

  describe 'GET /v1/conversations/:conversation_id/messages' do
    context 'with valid authorization' do
      it 'returns paginated messages with sender associations' do
        get "/v1/conversations/#{conversation.id}/messages", headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']).to be_an(Array)
        expect(json_response['data'].size).to eq(2)
        expect(json_response['meta']['total_count']).to eq(2)

        # First message is from customer
        expect(json_response['data'].first['content']).to eq('Hello support team')
        expect(json_response['data'].first['sender_type']).to eq('Customer')

        # Second message is from user
        expect(json_response['data'].second['content']).to eq('Hi! How can I help?')
        expect(json_response['data'].second['sender_type']).to eq('User')
      end

      it 'respects pagination params' do
        get "/v1/conversations/#{conversation.id}/messages", params: { page: 1, per_page: 1 }, headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(1)
        expect(json_response['meta']['per_page']).to eq(1)
        expect(json_response['meta']['total_pages']).to eq(2)
      end
    end

    context 'with conversation belonging to another account' do
      let!(:other_account) { create(:account) }
      let!(:other_inbox) { other_account.with_shard { create(:inbox, account: other_account) } }
      let!(:other_conversation) { other_account.with_shard { create(:conversation, account: other_account, inbox: other_inbox) } }

      it 'returns 404 not found' do
        get "/v1/conversations/#{other_conversation.id}/messages", headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('not_found')
      end
    end

    context 'when user lacks permission' do
      let!(:agent_user) { create(:user, confirmed_at: Time.current) }
      let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }

      it 'returns 403 forbidden' do
        get "/v1/conversations/#{conversation.id}/messages", headers: auth_headers(agent_user, account: account)

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('forbidden')
      end
    end
  end

  describe 'POST /v1/conversations/:conversation_id/messages' do
    let(:valid_params) do
      { content: 'Here is an update on your request.' }
    end

    context 'with valid parameters' do
      it 'creates a new message from the authenticated user' do
        expect do
          post "/v1/conversations/#{conversation.id}/messages", params: valid_params, headers: auth_headers(user, account: account)
        end.to change { account.with_shard { conversation.messages.count } }.by(1)

        expect(response).to have_http_status(:created).or have_http_status(:ok)
        expect(json_response['data']['content']).to eq('Here is an update on your request.')
        expect(json_response['data']['sender_type']).to eq('User')
        expect(json_response['data']['sender_id']).to eq(user.id)
        expect(json_response['data']['private']).to be false
      end

      it 'creates a private internal note when private is true' do
        expect do
          post "/v1/conversations/#{conversation.id}/messages",
               params: { content: 'Internal note: escalated to tier 2', private: true },
               headers: auth_headers(user, account: account)
        end.to change { account.with_shard { conversation.messages.count } }.by(1)

        expect(response).to have_http_status(:created).or have_http_status(:ok)
        expect(json_response['data']['content']).to eq('Internal note: escalated to tier 2')
        expect(json_response['data']['private']).to be true
        expect(json_response['data']['visibility']).to eq('personal')
      end

      it 'creates a message using response param alias and resolves conversation' do
        expect(conversation.assignee_id).to be_nil

        post "/v1/conversations/#{conversation.id}/messages",
             params: { response: 'Resolved issue for customer', resolve_conversation: true },
             headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:created)
        expect(json_response['data']['content']).to eq('Resolved issue for customer')
        expect(conversation.reload.assignee_id).to eq(user.id)
        expect(conversation.status).to eq('resolved')
      end
    end

    context 'with blank content' do
      it 'returns 422 unprocessable content' do
        post "/v1/conversations/#{conversation.id}/messages", params: { content: '' }, headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to be_an(Array)
      end
    end

    context 'with non-existent conversation' do
      it 'returns 404 not found' do
        post "/v1/conversations/#{SecureRandom.uuid}/messages", params: valid_params, headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('not_found')
      end
    end

    context 'when user lacks write permission' do
      let!(:agent_user) { create(:user, confirmed_at: Time.current) }
      let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }

      it 'returns 403 forbidden' do
        post "/v1/conversations/#{conversation.id}/messages", params: valid_params, headers: auth_headers(agent_user, account: account)

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('forbidden')
      end
    end
  end

  describe 'POST /v1/conversations/:conversation_id/messages/:id/translate' do
    let!(:msg) { account.with_shard { create(:message, account: account, conversation: conversation, inbox: inbox, sender: user, content: 'Hello how are you') } }

    it 'translates message to target locale' do
      post "/v1/conversations/#{conversation.id}/messages/#{msg.id}/translate",
           params: { target_locale: 'es' },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok).or have_http_status(:created)
      expect(json_response['data']['message_id']).to eq(msg.id)
      expect(json_response['data']['target_locale']).to eq('es')
      expect(json_response['data']['original_content']).to eq('Hello how are you')
    end
  end
end
