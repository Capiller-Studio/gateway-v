# frozen_string_literal: true

module V1
  class Root < Grape::API
    version 'v1', using: :path
    include Defaults

    # Mount resources here
    mount V1::Resources::Sessions
    mount V1::Resources::Registrations
    mount V1::Resources::Me
    mount V1::Resources::Profiles
    mount V1::Resources::Passwords
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
    mount V1::Resources::CustomAttributes
  end
end

