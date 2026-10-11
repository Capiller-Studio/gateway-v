# frozen_string_literal: true

module V1
  module Entities
    module Sdk
      class SenderEntity < Blueprinter::Base
        identifier :id

        field :type do |sender|
          case sender
          when Customer
            "customer"
          when User
            "agent"
          when Account, Ai::Agent
            "bot"
          else
            "unknown"
          end
        end

        field :name do |sender|
          if sender.is_a?(User)
            sender.display_name.presence || sender.name.presence || "Agent"
          elsif sender.is_a?(Customer)
            sender.display_name.presence || sender.name.presence || "You"
          else
            "Support Bot"
          end
        end

        field :avatar_url do |sender|
          if sender.respond_to?(:avatar) && sender.avatar.attached?
            Rails.application.routes.url_helpers.rails_blob_url(sender.avatar, only_path: false) rescue nil
          else
            nil
          end
        end
      end
    end
  end
end
