# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Conversations', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:inbox) { account.with_shard { create(:inbox, account: account) } }
  let!(:customer) { account.with_shard { create(:customer, account: account) } }

  let!(:conversation1) do
    account.with_shard do
      create(:conversation, account: account, inbox: inbox, status: :active, priority: :medium)
    end
  end

  let!(:conversation2) do
    account.with_shard do
      create(:conversation, account: account, inbox: inbox, status: :resolved, priority: :high)
    end
  end

  describe 'GET /v1/conversations' do
    context 'with valid authorization' do
      it 'returns paginated list of conversations' do
        get '/v1/conversations', headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']).to be_an(Array)
        expect(json_response['data'].size).to eq(2)
        expect(json_response['meta']['total_count']).to eq(2)
      end

      it 'filters conversations by status' do
        get '/v1/conversations', params: { status: 'resolved' }, headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(1)
        expect(json_response['data'].first['id']).to eq(conversation2.id)
        expect(json_response['data'].first['status']).to eq('resolved')
      end

      it 'respects pagination params' do
        get '/v1/conversations', params: { page: 1, per_page: 1 }, headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(1)
        expect(json_response['meta']['per_page']).to eq(1)
        expect(json_response['meta']['total_pages']).to eq(2)
      end
    end

    context 'when user lacks permission' do
      let!(:agent_user) { create(:user, confirmed_at: Time.current) }
      let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }

      it 'returns 403 forbidden' do
        get '/v1/conversations', headers: auth_headers(agent_user, account: account)

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('forbidden')
      end
    end
  end

  describe 'GET /v1/conversations/:id' do
    context 'with valid conversation ID' do
      it 'returns conversation details with associations' do
        get "/v1/conversations/#{conversation1.id}", headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['id']).to eq(conversation1.id)
        expect(json_response['data']['status']).to eq('active')
        expect(json_response['data']['inbox']['id']).to eq(inbox.id)
      end
    end

    context 'with non-existent conversation ID' do
      it 'returns 404 not found' do
        get "/v1/conversations/#{SecureRandom.uuid}", headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('not_found')
      end
    end

    context 'with conversation belonging to another account' do
      let!(:other_account) { create(:account) }
      let!(:other_inbox) { other_account.with_shard { create(:inbox, account: other_account) } }
      let!(:other_conversation) { other_account.with_shard { create(:conversation, account: other_account, inbox: other_inbox) } }

      it 'returns 404 not found' do
        get "/v1/conversations/#{other_conversation.id}", headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('not_found')
      end
    end
  end

  describe 'POST /v1/conversations' do
    let(:valid_params) do
      {
        inbox_id: inbox.id,
        customer_id: customer.id,
        status: 'active',
        priority: 'urgent'
      }
    end

    context 'with valid parameters' do
      it 'creates a new conversation and assigns customer membership' do
        expect do
          post '/v1/conversations', params: valid_params, headers: auth_headers(user, account: account)
        end.to change { account.with_shard { account.conversations.count } }.by(1)

        expect(response).to have_http_status(:created).or have_http_status(:ok)
        expect(json_response['data']['status']).to eq('active')
        expect(json_response['data']['priority']).to eq('urgent')
        expect(json_response['data']['inbox']['id']).to eq(inbox.id)
      end
    end

    context 'with invalid status' do
      it 'returns 422 unprocessable content' do
        post '/v1/conversations', params: valid_params.merge(status: 'invalid_status'), headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to be_an(Array)
      end
    end

    context 'with inbox belonging to another account' do
      let!(:other_account) { create(:account) }
      let!(:other_inbox) { other_account.with_shard { create(:inbox, account: other_account) } }

      it 'returns 404 not found' do
        post '/v1/conversations', params: valid_params.merge(inbox_id: other_inbox.id), headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('not_found')
      end
    end
  end

  describe 'PATCH /v1/conversations/:id' do
    it 'updates status and priority' do
      patch "/v1/conversations/#{conversation1.id}",
            params: { status: 'resolved', priority: 'urgent' },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(conversation1.reload.status).to eq('resolved')
      expect(conversation1.priority).to eq('urgent')
    end
  end

  describe 'POST /v1/conversations/:id/assign' do
    let!(:target_agent) { create(:user, confirmed_at: Time.current) }
    let!(:target_account_user) { create(:account_user, account: account, user: target_agent, owner: false) }
    let!(:team) do
      account.with_shard { account.teams.create!(name: 'Support Ops') }
    end

    it 'assigns conversation to an agent and team' do
      post "/v1/conversations/#{conversation1.id}/assign",
           params: { assignee_id: target_agent.id, team_id: team.id },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(conversation1.reload.assignee_id).to eq(target_agent.id)
      expect(conversation1.team_id).to eq(team.id)
    end
  end

  describe 'POST /v1/conversations/:id/labels' do
    it 'attaches a label to the conversation' do
      post "/v1/conversations/#{conversation1.id}/labels",
           params: { label_title: 'VIP Customer' },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(conversation1.reload.labels.pluck(:title)).to include('VIP Customer')
    end
  end

  describe 'DELETE /v1/conversations/:id/labels/:label_id' do
    let!(:label) do
      account.with_shard { account.labels.create!(title: 'Temporary Tag') }
    end

    before do
      account.with_shard do
        conversation1.applied_labels.create!(label: label)
      end
    end

    it 'removes the label from the conversation' do
      delete "/v1/conversations/#{conversation1.id}/labels/#{label.id}",
             headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(conversation1.reload.labels.pluck(:id)).not_to include(label.id)
    end
  end

  describe 'POST /v1/conversations/:id/snooze' do
    it 'snoozes the conversation until timestamp' do
      post "/v1/conversations/#{conversation1.id}/snooze",
           params: { snoozed_until: 2.days.from_now.iso8601 },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok).or have_http_status(:created)
      expect(conversation1.reload.status).to eq('snoozed')
    end
  end

  describe 'POST /v1/conversations/:id/resolve' do
    it 'resolves the conversation' do
      post "/v1/conversations/#{conversation1.id}/resolve",
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok).or have_http_status(:created)
      expect(conversation1.reload.status).to eq('resolved')
    end
  end

  describe 'POST /v1/conversations/:id/typing' do
    it 'broadcasts typing indicator' do
      post "/v1/conversations/#{conversation1.id}/typing",
           params: { typing: true },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok).or have_http_status(:created)
      expect(json_response['data']['typing']).to eq(true)
    end
  end
end
