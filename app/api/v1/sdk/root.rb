# frozen_string_literal: true

module V1
  module Sdk
    class Root < Grape::API
      helpers V1::Helpers::SdkAuthHelpers

      namespace :sdk do
        mount V1::Resources::Sdk::Config
        mount V1::Resources::Sdk::Session
        mount V1::Resources::Sdk::Conversations
        mount V1::Resources::Sdk::Messages
        mount V1::Resources::Sdk::Devices
        mount V1::Resources::Sdk::DirectUploads
        mount V1::Resources::Sdk::Unread
      end
    end
  end
end
