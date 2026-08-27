# frozen_string_literal: true

module V1
  module Entities
    class CustomerEntity < Blueprinter::Base
      identifier :id

      fields :name, :first_name, :last_name, :email, :full_phone_number, :display_name, :locale, :created_at, :updated_at

      field :avatar_url do |customer|
        if customer.avatar.attached?
          Rails.application.routes.url_helpers.rails_blob_url(customer.avatar, only_path: true)
        end
      end
    end
  end
end
