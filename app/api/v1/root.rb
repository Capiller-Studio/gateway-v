# frozen_string_literal: true

module V1
  class Root < Grape::API
    version 'v1', using: :path
    include Defaults

    # Mount resources here
    mount V1::Resources::Auth
    mount V1::Resources::Me
    mount V1::Resources::Devices
    mount V1::Resources::Inboxes
    mount V1::Resources::Customers
    mount V1::Resources::Conversations
    mount V1::Resources::Messages
    mount V1::Resources::Agents
    mount V1::Resources::Teams
    mount V1::Resources::CannedResponses
    mount V1::Resources::Labels
    mount V1::Resources::Notifications
    mount V1::Resources::NotificationSettings
    mount V1::Resources::Searches
    mount V1::Resources::Attachments
    mount V1::Resources::System
    mount V1::Resources::CustomFields
    mount V1::Resources::Macros
    mount V1::Resources::Webhooks
    # mount V1::Resources::ApiKeys

    mount V1::Sdk::Root
  end
end

