# frozen_string_literal: true

module V1
  module Resources
    class Attachments < Grape::API
      resource :attachments do
        before do
          authenticate_user!
          check_subscription!
        end

        desc 'Generate pre-signed direct upload metadata for ActiveStorage'
        params do
          requires :filename, type: String, allow_blank: false
          requires :byte_size, type: Integer, values: ->(v) { v.positive? }
          requires :checksum, type: String, allow_blank: false
          requires :content_type, type: String, allow_blank: false
        end
        post :direct_uploads do
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

        desc 'Upload an attachment directly via multipart or attach signed blob'
        params do
          optional :signed_blob_id, type: String
          optional :file, type: File
          optional :attachment_type, type: String, values: Attachment.attachment_types.keys, default: 'file'
          optional :resource_type, type: String
          optional :resource_id, type: String
          at_least_one_of :signed_blob_id, :file
        end
        post do
          attachment = current_account.with_shard do
            res_type = params[:resource_type].presence || 'Account'
            res_id = params[:resource_id].presence || current_account.id

            att = current_account.attachments.new(
              attachment_type: params[:attachment_type],
              resource_type: res_type,
              resource_id: res_id
            )

            if params[:signed_blob_id].present?
              blob = ActiveStorage::Blob.find_signed!(params[:signed_blob_id])
              att.file.attach(blob)
            elsif params[:file].present?
              file_data = params[:file]
              att.file.attach(
                io: File.open(file_data[:tempfile]),
                filename: file_data[:filename],
                content_type: file_data[:type]
              )
            end

            att.extension = File.extname(att.file.filename.to_s).downcase if att.file.attached?
            att.save!
            att
          end

          success(data: V1::Entities::AttachmentEntity.render_as_hash(attachment))
        end
      end
    end
  end
end
