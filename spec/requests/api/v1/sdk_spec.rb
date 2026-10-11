# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Sdk', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) do
    create(:plan, features: { 'channels' => { 'mobile_widget' => true } }, limits: { 'channels' => 100, 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:channel) do
    account.with_shard do
      create(:channel_mobile_widget, account: account, name: 'Mobile App Support')
    end
  end

  let!(:inbox) do
    account.with_shard do
      create(:inbox, account: account, channel: channel, primary_inbox: true, name: 'Mobile Support')
    end
  end

  let(:sdk_headers) do
    { 'X-Deskbolic-App-Id' => channel.identifier }
  end

  before do
    Rails.cache.clear
  end

  describe 'GET /v1/sdk/config' do
    it 'returns mobile channel configuration' do
      get '/v1/sdk/config', headers: sdk_headers

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data']['app_id']).to eq(channel.identifier)
      expect(json_response['data']['name']).to eq('Mobile App Support')
      expect(json_response['data']['features']['anonymous_allowed']).to be true
      expect(json_response['data']['theme']['primary_color']).to eq('#0F766E')
    end

    it 'returns 401 when X-Deskbolic-App-Id is missing or invalid' do
      get '/v1/sdk/config', headers: { 'X-Deskbolic-App-Id' => 'invalid_id' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['errors'].first['code']).to eq('invalid_app_id')
    end

    it 'returns 401 when channel is not found in routing' do
      get '/v1/sdk/config', headers: { 'X-Deskbolic-App-Id' => 'dbk_app_nonexistent0001' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['errors'].first['code']).to eq('channel_not_found')
    end

    it 'returns 401 when account is suspended or inactive' do
      account.update!(status: :suspended)

      get '/v1/sdk/config', headers: sdk_headers

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['errors'].first['code']).to eq('account_inactive')
    end

    it 'returns 403 when mobile_widget feature is disabled on plan' do
      plan.update!(features: { 'channels' => { 'mobile_widget' => false } })

      get '/v1/sdk/config', headers: sdk_headers

      expect(response).to have_http_status(:forbidden)
      expect(json_response['errors'].first['code']).to eq('feature_disabled')
    end

    it 'returns 402 when subscription is inactive' do
      subscription.update!(status: :cancelled)

      get '/v1/sdk/config', headers: sdk_headers

      expect(response).to have_http_status(:payment_required)
      expect(json_response['errors'].first['code']).to eq('payment_required')
    end
  end

  describe 'POST /v1/sdk/session' do
    context 'anonymous session' do
      it 'creates guest customer and returns session token' do
        post '/v1/sdk/session', params: {
          name: 'Guest Tester'
        }, headers: sdk_headers

        expect(response).to have_http_status(:created)
        expect(json_response['success']).to be true
        expect(json_response['data']['session_token']).to be_present
        expect(json_response['data']['connection_token']).to be_present
        expect(json_response['data']['customer']['name']).to eq('Guest Tester')
      end

      it 'rejects guest session when anonymous_allowed is false' do
        account.with_shard { channel.update!(anonymous_allowed: false) }

        post '/v1/sdk/session', params: {
          name: 'Guest Tester'
        }, headers: sdk_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors'].first['code']).to eq('anonymous_disabled')
      end

      it 'rejects guest session when secure_identity_enforced is true' do
        account.with_shard { channel.update!(secure_identity_enforced: true) }

        post '/v1/sdk/session', params: {
          name: 'Guest Tester'
        }, headers: sdk_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors'].first['code']).to eq('identity_verification_failed')
      end
    end

    context 'authenticated session with JWT identity' do
      let(:customer_external_id) { 'usr_789' }
      let(:jwt_payload) do
        {
          external_id: customer_external_id,
          email: 'jane@example.com',
          name: 'Jane Doe',
          exp: (Time.current + 1.hour).to_i
        }
      end
      let(:identity_token) { JWT.encode(jwt_payload, channel.secret, 'HS256') }

      it 'authenticates customer via JWT and returns verified customer' do
        post '/v1/sdk/session', params: {
          jwt: identity_token
        }, headers: sdk_headers

        expect(response).to have_http_status(:created)
        expect(json_response['success']).to be true
        expect(json_response['data']['session_token']).to be_present
        expect(json_response['data']['customer']['email']).to eq('jane@example.com')
        expect(json_response['data']['customer']['name']).to eq('Jane Doe')
      end

      it 'rejects invalid JWT signature' do
        invalid_token = JWT.encode(jwt_payload, 'wrong_secret', 'HS256')

        post '/v1/sdk/session', params: {
          jwt: invalid_token
        }, headers: sdk_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors'].first['code']).to eq('identity_verification_failed')
      end

      it 'rejects expired JWT' do
        expired_payload = jwt_payload.merge(exp: (Time.current - 1.minute).to_i)
        expired_token = JWT.encode(expired_payload, channel.secret, 'HS256')

        post '/v1/sdk/session', params: {
          jwt: expired_token
        }, headers: sdk_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors'].first['code']).to eq('identity_verification_failed')
      end
    end

    context 'authenticated session with HMAC signature' do
      let(:customer_external_id) { 'hmac_user_456' }
      let(:identity_hash) do
        OpenSSL::HMAC.hexdigest('sha256', channel.secret, customer_external_id)
      end

      it 'authenticates customer via HMAC hash' do
        post '/v1/sdk/session', params: {
          identifier: customer_external_id,
          signature: identity_hash,
          email: 'hmac@example.com',
          name: 'HMAC User'
        }, headers: sdk_headers

        expect(response).to have_http_status(:created)
        expect(json_response['success']).to be true
        expect(json_response['data']['customer']['name']).to eq('HMAC User')
      end

      it 'rejects mismatched signature' do
        post '/v1/sdk/session', params: {
          identifier: customer_external_id,
          signature: 'mismatched_hex_signature',
          name: 'HMAC User'
        }, headers: sdk_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors'].first['code']).to eq('identity_verification_failed')
      end
    end

    context 'conversation stitching from guest to authenticated user' do
      it 'stitches anonymous conversations to the newly authenticated customer' do
        # 1. Anonymous session creates conversation
        post '/v1/sdk/session', params: { name: 'Anonymous Shopper' }, headers: sdk_headers
        expect(response).to have_http_status(:created)
        anon_token = json_response['data']['session_token']

        post '/v1/sdk/conversations', params: { content: 'Where is my order #1234?' },
             headers: sdk_headers.merge('X-Customer-Session-Token' => anon_token)
        expect(response).to have_http_status(:created)
        anon_conv_id = json_response['data']['id']

        # 2. User logs in with JWT and passes previous_session_token
        auth_jwt = JWT.encode({ external_id: 'cust_real_100', email: 'real@example.com', name: 'Real User' }, channel.secret, 'HS256')
        post '/v1/sdk/session', params: {
          jwt: auth_jwt,
          previous_session_token: anon_token
        }, headers: sdk_headers

        expect(response).to have_http_status(:created)
        auth_token = json_response['data']['session_token']

        # 3. Authenticated customer now owns the conversation and message history
        get '/v1/sdk/conversations', headers: sdk_headers.merge('X-Customer-Session-Token' => auth_token)
        expect(response).to have_http_status(:ok)
        conv_ids = json_response['data'].map { |c| c['id'] }
        expect(conv_ids).to include(anon_conv_id)

        get "/v1/sdk/conversations/#{anon_conv_id}/messages", headers: sdk_headers.merge('X-Customer-Session-Token' => auth_token)
        expect(response).to have_http_status(:ok)
        expect(json_response['data'].first['content']).to eq('Where is my order #1234?')
      end
    end
  end

  describe 'Session-authenticated operations' do
    let!(:customer) do
      account.with_shard do
        create(:customer, account: account, name: 'Alice Mobile', email: 'alice@mobile.app')
      end
    end

    let!(:customer_inbox) do
      account.with_shard do
        create(:customer_inbox, inbox: inbox, customer: customer)
      end
    end

    let(:session_token) do
      Channels::MobileWidgets::SessionToken.encode(
        customer: customer,
        customer_inbox: customer_inbox,
        channel: channel
      )
    end

    let(:auth_sdk_headers) do
      sdk_headers.merge('X-Customer-Session-Token' => session_token)
    end

    describe 'Authentication edge cases' do
      it 'returns 401 when session token is missing' do
        get '/v1/sdk/conversations', headers: sdk_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors'].first['code']).to eq('session_token_required')
      end

      it 'returns 401 when session token is invalid or expired' do
        get '/v1/sdk/conversations', headers: sdk_headers.merge('X-Customer-Session-Token' => 'invalid.session.jwt')

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors'].first['code']).to eq('invalid_session_token')
      end
    end

    describe 'PATCH /v1/sdk/session/customer' do
      it 'updates customer profile information' do
        patch '/v1/sdk/session/customer', params: {
          name: 'Alice Updated'
        }, headers: auth_sdk_headers

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['name']).to eq('Alice Updated')
      end
    end

    describe 'Conversations and Messages lifecycle' do
      it 'creates a conversation and sends messages' do
        # 1. Create Conversation
        post '/v1/sdk/conversations', params: {
          content: 'Need assistance with order #9921'
        }, headers: auth_sdk_headers

        expect(response).to have_http_status(:created)
        conversation_id = json_response['data']['id']
        expect(conversation_id).to be_present

        # 2. List Conversations
        get '/v1/sdk/conversations', headers: auth_sdk_headers
        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(1)

        # 3. Send a follow-up message
        post "/v1/sdk/conversations/#{conversation_id}/messages", params: {
          content: 'Here is additional detail',
          client_message_id: 'client_msg_uuid_001'
        }, headers: auth_sdk_headers

        expect(response).to have_http_status(:created)
        expect(json_response['data']['content']).to eq('Here is additional detail')
        expect(json_response['data']['sender']['name']).to eq(customer.name)

        # 4. Idempotency check: sending duplicate client_message_id returns the same message
        post "/v1/sdk/conversations/#{conversation_id}/messages", params: {
          content: 'Here is additional detail',
          client_message_id: 'client_msg_uuid_001'
        }, headers: auth_sdk_headers

        expect(response).to have_http_status(:created)
        expect(json_response['data']['content']).to eq('Here is additional detail')

        # 5. List messages for conversation
        get "/v1/sdk/conversations/#{conversation_id}/messages", headers: auth_sdk_headers
        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(2)

        # 6. Mark conversation as read
        post "/v1/sdk/conversations/#{conversation_id}/read", headers: auth_sdk_headers
        expect(response).to have_http_status(:created)
        expect(json_response['success']).to be true
      end

      it 'returns conversation details for owned conversation and 404 for non-existent conversation' do
        post '/v1/sdk/conversations', params: { content: 'Need order help' }, headers: auth_sdk_headers
        conv_id = json_response['data']['id']

        get "/v1/sdk/conversations/#{conv_id}", headers: auth_sdk_headers
        expect(response).to have_http_status(:ok)
        expect(json_response['data']['id']).to eq(conv_id)

        get "/v1/sdk/conversations/#{SecureRandom.uuid}", headers: auth_sdk_headers
        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('conversation_not_found')
      end

      it 'returns 404 when posting message to non-existent conversation' do
        post "/v1/sdk/conversations/#{SecureRandom.uuid}/messages", params: { content: 'Missing conversation test' }, headers: auth_sdk_headers

        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('conversation_not_found')
      end

      it 'returns 403 when sending attachments while attachments are disabled on channel' do
        post '/v1/sdk/conversations', params: { content: 'Initial msg' }, headers: auth_sdk_headers
        conv_id = json_response['data']['id']

        account.with_shard { channel.update!(attachments_enabled: false) }

        post "/v1/sdk/conversations/#{conv_id}/messages", params: {
          content: 'Here is an attachment',
          attachment_ids: ['signed_blob_id_001']
        }, headers: auth_sdk_headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('attachments_disabled')
      end

      it 'supports cursor pagination with limit and message order' do
        post '/v1/sdk/conversations', params: { content: 'Msg 1' }, headers: auth_sdk_headers
        conv_id = json_response['data']['id']

        msg2_id = nil
        3.times do |i|
          post "/v1/sdk/conversations/#{conv_id}/messages", params: { content: "Msg #{i + 2}" }, headers: auth_sdk_headers
          msg2_id = json_response['data']['id'] if i == 0
        end

        # Request with limit 2
        get "/v1/sdk/conversations/#{conv_id}/messages", params: { limit: 2 }, headers: auth_sdk_headers
        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(2)
        expect(json_response['meta']['limit']).to eq(2)
        expect(json_response['meta']['count']).to eq(2)

        # Request catch-up messages after msg2_id
        get "/v1/sdk/conversations/#{conv_id}/messages", params: { after_id: msg2_id }, headers: auth_sdk_headers
        expect(response).to have_http_status(:ok)
        expect(json_response['data'].size).to eq(2)
      end

      it 'does not expose private agent notes to mobile customer' do
        conv = account.with_shard do
          c = create(:conversation, account: account, inbox: inbox)
          c.conversation_members.create!(member: customer, account: account)
          # Outgoing agent message
          create(:message, account: account, conversation: c, inbox: inbox, sender: user, content: 'Public reply', visibility: :global)
          # Private agent note
          create(:message, account: account, conversation: c, inbox: inbox, sender: user, content: 'Secret internal note', visibility: :personal)
          c
        end

        get "/v1/sdk/conversations/#{conv.id}/messages", headers: auth_sdk_headers

        expect(response).to have_http_status(:ok)
        contents = json_response['data'].map { |m| m['content'] }
        expect(contents).to include('Public reply')
        expect(contents).not_to include('Secret internal note')
      end
    end

    describe 'POST /v1/sdk/direct_uploads' do
      let(:upload_params) do
        {
          filename: 'device_logs.txt',
          byte_size: 1024,
          checksum: Base64.strict_encode64(OpenSSL::Digest::MD5.digest('device log content')),
          content_type: 'text/plain'
        }
      end

      it 'generates direct upload metadata for ActiveStorage' do
        post '/v1/sdk/direct_uploads', params: upload_params, headers: auth_sdk_headers

        expect(response).to have_http_status(:created)
        expect(json_response['success']).to be true
        expect(json_response['data']['id']).to be_present
        expect(json_response['data']['signed_id']).to be_present
        expect(json_response['data']['direct_upload']['url']).to be_present
      end

      it 'returns 403 when attachments are disabled on channel' do
        account.with_shard { channel.update!(attachments_enabled: false) }

        post '/v1/sdk/direct_uploads', params: upload_params, headers: auth_sdk_headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('attachments_disabled')
      end

      it 'returns 422 when byte_size exceeds max_attachment_mb' do
        account.with_shard { channel.update!(configurations: { 'max_attachment_mb' => 2 }) }

        post '/v1/sdk/direct_uploads', params: upload_params.merge(byte_size: 5.megabytes), headers: auth_sdk_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors'].first['code']).to eq('file_too_large')
      end
    end

    describe 'POST /v1/sdk/devices and DELETE /v1/sdk/devices/:token' do
      it 'registers and unregisters customer push device' do
        test_token = "apns_#{SecureRandom.hex(8)}"
        post '/v1/sdk/devices', params: {
          push_token: test_token,
          platform: 'ios',
          device_model: 'iPhone 16 Pro',
          os_version: 'iOS 18.2'
        }, headers: auth_sdk_headers

        expect(response).to have_http_status(:created)
        expect(json_response['success']).to be true
        expect(json_response['data']['push_token']).to eq(test_token)

        # Verify device in DB
        account.with_shard do
          expect(inbox.customer_devices.find_by(push_token: test_token)).to be_active
        end

        # Unregister device
        delete "/v1/sdk/devices/#{test_token}", headers: auth_sdk_headers
        expect(response).to have_http_status(:ok)
        expect(json_response['success']).to be true

        account.with_shard do
          expect(inbox.customer_devices.find_by(push_token: test_token)).to be_nil
        end
      end

      it 'updates existing device record when token is re-registered' do
        token = "apns_unique_#{SecureRandom.hex(6)}"

        # Initial registration
        post '/v1/sdk/devices', params: {
          push_token: token,
          platform: 'ios',
          app_version: '1.0.0'
        }, headers: auth_sdk_headers
        expect(response).to have_http_status(:created)

        # Re-registration with updated app_version
        post '/v1/sdk/devices', params: {
          push_token: token,
          platform: 'ios',
          app_version: '1.1.0'
        }, headers: auth_sdk_headers
        expect(response).to have_http_status(:created)

        account.with_shard do
          device = inbox.customer_devices.find_by(push_token: token)
          expect(device.app_version).to eq('1.1.0')
          expect(inbox.customer_devices.where(push_token: token).count).to eq(1)
        end
      end
    end

    describe 'GET /v1/sdk/unread_count' do
      it 'returns unread message count' do
        get '/v1/sdk/unread_count', headers: auth_sdk_headers

        expect(response).to have_http_status(:ok)
        expect(json_response['success']).to be true
        expect(json_response['data']).to have_key('unread_count')
      end
    end

    describe 'DELETE /v1/sdk/session' do
      it 'ends session and unregisters specified device' do
        account.with_shard do
          create(:customer_device, account: account, inbox: inbox, customer: customer, customer_inbox: customer_inbox, push_token: 'active_dev_1')
        end

        delete '/v1/sdk/session', params: { device_token: 'active_dev_1' }, headers: auth_sdk_headers

        expect(response).to have_http_status(:ok)
        expect(json_response['success']).to be true

        account.with_shard do
          expect(CustomerDevice.find_by(push_token: 'active_dev_1')).to be_nil
        end
      end
    end

    describe 'Rack::Attack SDK rate limits' do
      it 'tracks sdk/ip throttle discriminator for SDK endpoints' do
        request = Rack::Attack::Request.new('PATH_INFO' => '/v1/sdk/config', 'REMOTE_ADDR' => '203.0.113.42')
        throttle = Rack::Attack.throttles['sdk/ip']
        expect(throttle).to be_present
        expect(throttle.block.call(request)).to eq('203.0.113.42')
      end

      it 'ignores non-SDK endpoints for sdk/ip throttle' do
        request = Rack::Attack::Request.new('PATH_INFO' => '/v1/conversations', 'REMOTE_ADDR' => '203.0.113.42')
        throttle = Rack::Attack.throttles['sdk/ip']
        expect(throttle.block.call(request)).to be_nil
      end

      it 'tracks sdk/messages/create throttle discriminator for SDK message posts' do
        request = Rack::Attack::Request.new(
          'REQUEST_METHOD' => 'POST',
          'PATH_INFO' => '/v1/sdk/conversations/conv-123/messages',
          'REMOTE_ADDR' => '203.0.113.42'
        )
        throttle = Rack::Attack.throttles['sdk/messages/create']
        expect(throttle).to be_present
        expect(throttle.block.call(request)).to eq('203.0.113.42')
      end
    end
  end
end
