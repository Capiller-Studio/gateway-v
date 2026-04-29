# frozen_string_literal: true

module V1
  module Entities
    class UserEntity < Blueprinter::Base
      identifier :id
      fields :email, :first_name, :last_name, :display_name, :status, :created_at
      
      view :extended do
        association :affiliate_profile, blueprint: V1::Entities::AffiliateProfileEntity
      end
    end
  end
end
