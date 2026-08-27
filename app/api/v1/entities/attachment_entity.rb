# frozen_string_literal: true

module V1
  module Entities
    class AttachmentEntity < Blueprinter::Base
      identifier :id

      fields :attachment_type, :extension, :remote_url, :created_at

      field :file_url do |attachment|
        attachment.direct_download_url
      end
    end
  end
end
