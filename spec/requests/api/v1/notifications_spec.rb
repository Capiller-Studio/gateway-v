# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Notifications', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: user) }
  let(:headers) { auth_headers(user, account: account) }
  let!(:conversation) do
    account.with_shard do
      inbox = create(:inbox, account: account)
      create(:conversation, account: account, inbox: inbox)
    end
  end

  before do
    allow(account).to receive(:subscribed?).and_return(true)
    allow_any_instance_of(Account).to receive(:subscribed?).and_return(true)
  end

  describe 'GET /v1/notifications' do
    before do
      account.with_shard { Notification.delete_all }
    end

    let!(:notification1) do
      account.with_shard do
        create(:notification, account: account, user: user, resource: conversation, event: :conversation_created, read_at: nil)
      end
    end
    let!(:notification2) do
      account.with_shard do
        create(:notification, account: account, user: user, resource: conversation, event: :conversation_assigned, read_at: 1.hour.ago)
      end
    end

    it 'returns paginated notifications for the current user' do
      get '/v1/notifications', headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response[:data]).to be_an(Array)
      expect(json_response[:data].length).to eq(2)
      expect(json_response[:meta]).to include(:current_page, :total_count)
    end

    it 'filters unread notifications when unread=true' do
      get '/v1/notifications', params: { unread: true }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response[:data].length).to eq(1)
      expect(json_response[:data].first[:id]).to eq(notification1.id)
      expect(json_response[:data].first[:read]).to be(false)
    end

    it 'does not return notifications belonging to other users' do
      other_user = create(:user)
      create(:account_user, account: account, user: other_user)
      account.with_shard do
        create(:notification, account: account, user: other_user, resource: conversation)
      end

      get '/v1/notifications', headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_response[:data].length).to eq(2)
    end

    it 'returns 401 when unauthenticated' do
      get '/v1/notifications'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 402 when subscription is inactive' do
      allow_any_instance_of(Account).to receive(:subscribed?).and_return(false)
      get '/v1/notifications', headers: headers
      expect(response).to have_http_status(:payment_required)
    end
  end

  describe 'GET /v1/notifications/unread_count' do
    before do
      account.with_shard do
        Notification.delete_all
        create(:notification, account: account, user: user, resource: conversation, read_at: nil)
        create(:notification, account: account, user: user, resource: conversation, read_at: nil)
        create(:notification, account: account, user: user, resource: conversation, read_at: Time.current)
      end
    end

    it 'returns the exact unread count for current user' do
      get '/v1/notifications/unread_count', headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response[:data][:unread_count]).to eq(2)
    end
  end

  describe 'PATCH /v1/notifications/:id/read' do
    before do
      account.with_shard { Notification.delete_all }
    end

    let!(:unread_notif) do
      account.with_shard do
        create(:notification, account: account, user: user, resource: conversation, read_at: nil)
      end
    end

    it 'marks the notification as read' do
      patch "/v1/notifications/#{unread_notif.id}/read", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response[:data][:read]).to be(true)
      expect(json_response[:data][:read_at]).not_to be_nil

      account.with_shard do
        expect(unread_notif.reload.read_at).not_to be_nil
      end
    end

    it 'returns 404 if notification belongs to another user' do
      other_user = create(:user)
      create(:account_user, account: account, user: other_user)
      other_notif = account.with_shard do
        create(:notification, account: account, user: other_user, resource: conversation)
      end

      patch "/v1/notifications/#{other_notif.id}/read", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /v1/notifications/read_all' do
    before do
      account.with_shard do
        Notification.delete_all
        create(:notification, account: account, user: user, resource: conversation, read_at: nil)
        create(:notification, account: account, user: user, resource: conversation, read_at: nil)
        create(:notification, account: account, user: user, resource: conversation, read_at: 1.day.ago)
      end
    end

    it 'marks all unread notifications as read' do
      post '/v1/notifications/read_all', headers: headers

      expect(response).to have_http_status(:created).or have_http_status(:ok)
      expect(json_response[:data][:success]).to be(true)
      expect(json_response[:data][:updated_count]).to eq(2)

      account.with_shard do
        expect(Notification.where(account_id: account.id, user_id: user.id).unread.count).to eq(0)
      end
    end
  end
end
