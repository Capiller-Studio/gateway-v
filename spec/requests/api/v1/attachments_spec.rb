# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::Attachments', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) { create(:plan, features: { 'channels' => { 'api' => true } }, limits: { 'channels' => 100, 'users' => 100 }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  describe 'POST /v1/attachments/direct_uploads' do
    it 'generates direct upload metadata' do
      post '/v1/attachments/direct_uploads',
           params: {
             filename: 'screenshot.png',
             byte_size: 1024,
             checksum: Digest::MD5.base64digest('fake_image_content'),
             content_type: 'image/png'
           },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:created)
      expect(json_response['data']).to have_key('signed_id')
      expect(json_response['data']['direct_upload']).to have_key('url')
      expect(json_response['data']['direct_upload']).to have_key('headers')
    end
  end

  describe 'POST /v1/attachments' do
    it 'creates an attachment via signed_blob_id' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('hello world test attachment'),
        filename: 'document.pdf',
        content_type: 'application/pdf'
      )

      post '/v1/attachments',
           params: {
             signed_blob_id: blob.signed_id,
             attachment_type: 'file'
           },
           headers: auth_headers(user, account: account)

      expect(response).to have_http_status(:created)
      expect(json_response['data']['attachment_type']).to eq('file')
      expect(json_response['data']['extension']).to eq('.pdf')
    end
  end
end
