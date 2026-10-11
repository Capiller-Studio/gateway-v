# frozen_string_literal: true

module V1
  module Entities
    module Sdk
      class CustomerEntity < Blueprinter::Base
        identifier :id

        fields :name, :first_name, :last_name, :email, :full_phone_number, :locale

        field :avatar_url do |customer|
          if customer.respond_to?(:avatar) && customer.avatar.attached?
            Rails.application.routes.url_helpers.rails_blob_url(customer.avatar, only_path: false) rescue nil
          else
            nil
          end
        end
      end
    end
  end
end
