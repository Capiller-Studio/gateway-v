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

      field :custom_attributes do |customer|
        customer.data || {}
      end

      field :address do |customer|
        if (addr = customer.address)
          {
            address1: addr.address1,
            address2: addr.address2,
            city: addr.city,
            state: addr.state_name.presence || addr.state&.abbr,
            country: addr.country&.iso_name || addr.country&.iso,
            zipcode: addr.zipcode
          }
        end
      end

      field :conversations_count do |customer|
        customer.conversations.count rescue 0
      end
    end
  end
end
