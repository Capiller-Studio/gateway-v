# frozen_string_literal: true

module V1
  module Resources
    module Sdk
      class DirectUploads < Grape::API
        resource :direct_uploads do
          before do
            authenticate_sdk_customer!
          end

          desc 'Generate pre-signed direct upload metadata for ActiveStorage'
          params do
            requires :filename, type: String, allow_blank: false
            requires :byte_size, type: Integer, values: ->(v) { v.positive? }
            requires :checksum, type: String, allow_blank: false
            requires :content_type, type: String, allow_blank: false
          end
          post do
            unless current_channel.attachments_enabled?
              failure(errors: [{ code: "attachments_disabled", message: "File attachments are disabled for this channel" }], status: 403)
            end

            max_mb = (current_channel.max_attachment_mb.presence || 20).to_i
            if params[:byte_size] > max_mb.megabytes
              failure(errors: [{ code: "file_too_large", message: "File size exceeds the #{max_mb} MB limit" }], status: 422)
            end

            ActiveStorage::Current.url_options = {
              host: request.host.presence || 'localhost',
              port: ([80, 443].include?(request.port) ? nil : request.port),
              protocol: request.scheme.presence || 'http'
            }

            blob = ActiveStorage::Blob.create_before_direct_upload!(
              filename: params[:filename],
              byte_size: params[:byte_size],
              checksum: params[:checksum],
              content_type: params[:content_type]
            )

            success(
              data: {
                id: blob.id,
                key: blob.key,
                signed_id: blob.signed_id,
                direct_upload: {
                  url: blob.service_url_for_direct_upload,
                  headers: blob.service_headers_for_direct_upload
                }
              }
            )
          end
        end
      end
    end
  end
end
