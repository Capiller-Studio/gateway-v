# frozen_string_literal: true

module V1
  class Root < Grape::API
    version 'v1', using: :path
    include Defaults

    # Mount resources here
    mount V1::Resources::Sessions
    mount V1::Resources::Registrations
    mount V1::Resources::Me
    mount V1::Resources::Inboxes
    mount V1::Resources::Customers
    mount V1::Resources::Conversations
    mount V1::Resources::Messages
  end
end
