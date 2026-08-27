# frozen_string_literal: true

module V1
  module Entities
    class UserEntity < Blueprinter::Base
      identifier :id
      fields :email, :first_name, :last_name, :display_name, :locale, :status, :created_at

      field :avatar_url do |user|
        if user.avatar.attached?
          Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: true)
        end
      end

      field :connection_token, if: ->(_field_name, _user, options) { options[:is_self] == true } do |user, _options|
        user.connection_token
      end

      view :extended do
        association :affiliate_profile, blueprint: V1::Entities::AffiliateProfileEntity
      end
    end
  end
end

