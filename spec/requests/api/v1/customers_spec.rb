# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Customers', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:customer1) { account.with_shard { create(:customer, account: account, name: 'Alice Smith', email: 'alice@example.com') } }
  let!(:customer2) { account.with_shard { create(:customer, account: account, name: 'Bob Jones', email: 'bob@example.com') } }

  describe 'GET /v1/customers' do
    context 'with valid authorization and active subscription' do
      it 'returns paginated list of customers with pagination metadata' do
        get '/v1/customers', headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']).to be_an(Array)
        expect(json_response['data'].size).to eq(2)
        expect(json_response['meta']['total_count']).to eq(2)
        expect(json_response['meta']['current_page']).to eq(1)
      end

      it 'respects pagination params' do
        get '/v1/customers', params: { page: 1, per_page: 1 }, headers: auth_headers(user, account: account)

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
        get '/v1/customers', headers: auth_headers(agent_user, account: account)

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('forbidden')
      end
    end
  end

  describe 'GET /v1/customers/:id' do
    context 'with valid customer ID' do
      it 'returns customer details' do
        get "/v1/customers/#{customer1.id}", headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['id']).to eq(customer1.id)
        expect(json_response['data']['name']).to eq('Alice Smith')
        expect(json_response['data']['email']).to eq('alice@example.com')
      end
    end

    context 'with non-existent customer ID' do
      it 'returns 404 not found' do
        get "/v1/customers/#{SecureRandom.uuid}", headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('not_found')
      end
    end

    context 'with customer belonging to another account' do
      let!(:other_account) { create(:account) }
      let!(:other_customer) { other_account.with_shard { create(:customer, account: other_account) } }

      it 'returns 404 not found' do
        get "/v1/customers/#{other_customer.id}", headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('not_found')
      end
    end
  end

  describe 'POST /v1/customers' do
    let(:valid_params) do
      {
        name: 'Charlie Brown',
        email: 'charlie@example.com',
        phone_number: '+15551234567'
      }
    end

    context 'with valid parameters' do
      it 'creates a new customer and returns customer entity' do
        expect do
          post '/v1/customers', params: valid_params, headers: auth_headers(user, account: account)
        end.to change { account.with_shard { account.customers.count } }.by(1)

        expect(response).to have_http_status(:created).or have_http_status(:ok)
        expect(json_response['data']['name']).to eq('Charlie Brown')
        expect(json_response['data']['email']).to eq('charlie@example.com')
        expect(json_response['data']['full_phone_number']).to eq('+15551234567')
      end
    end

    context 'with invalid email' do
      it 'returns 422 unprocessable content' do
        post '/v1/customers', params: valid_params.merge(email: 'not-an-email'), headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to be_an(Array)
      end
    end

    context 'with missing name' do
      it 'returns 422 unprocessable content' do
        post '/v1/customers', params: { email: 'charlie@example.com' }, headers: auth_headers(user, account: account)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to be_an(Array)
      end
    end

    context 'when user lacks write permission' do
      let!(:agent_user) { create(:user, confirmed_at: Time.current) }
      let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }

      it 'returns 403 forbidden' do
        post '/v1/customers', params: valid_params, headers: auth_headers(agent_user, account: account)

        expect(response).to have_http_status(:forbidden)
        expect(json_response['errors'].first['code']).to eq('forbidden')
      end
    end
  end

  describe 'PATCH /v1/customers/:id' do
    it 'updates customer details and custom attributes' do
      patch "/v1/customers/#{customer1.id}",
            params: {
              name: 'Alice Johnson',
              custom_attributes: { 'vip_tier' => 'Platinum' }
            },
            headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(customer1.reload.name).to eq('Alice Johnson')
      expect(customer1.data['vip_tier']).to eq('Platinum')
    end
  end

  describe 'DELETE /v1/customers/:id' do
    it 'deletes a customer' do
      delete "/v1/customers/#{customer1.id}", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(account.with_shard { Customer.find_by(id: customer1.id) }).to be_nil
    end
  end

  describe 'GET /v1/customers/:id/conversations' do
    let!(:inbox) { account.with_shard { create(:inbox, account: account) } }
    let!(:conv) do
      account.with_shard do
        c = create(:conversation, account: account, inbox: inbox)
        c.conversation_members.create!(member: customer1, account: account)
        c
      end
    end

    it 'returns customer conversation history' do
      get "/v1/customers/#{customer1.id}/conversations", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to be >= 1
      expect(json_response['data'].first['id']).to eq(conv.id)
    end
  end

  describe 'Customer Notes Subresource' do
    it 'creates an internal note for the customer' do
      post "/v1/customers/#{customer1.id}/notes",
           params: { content: 'Customer requested follow-up next Tuesday.' },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok).or have_http_status(:created)
      expect(json_response['success']).to be true
      expect(json_response['data']['content']).to eq('Customer requested follow-up next Tuesday.')
      expect(json_response['data']['user_id']).to eq(user.id)
    end

    it 'lists customer internal notes' do
      account.with_shard do
        customer1.notes.create!(
          account: account,
          user: user,
          content: 'Initial customer note',
          visibility: :personal
        )
      end

      get "/v1/customers/#{customer1.id}/notes", headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be true
      expect(json_response['data'].size).to eq(1)
      expect(json_response['data'].first['content']).to eq('Initial customer note')
    end
  end
end
