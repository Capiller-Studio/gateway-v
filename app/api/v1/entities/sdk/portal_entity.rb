# frozen_string_literal: true

module V1
  module Entities
    module Sdk
      class PortalEntity < Blueprinter::Base
        identifier :id

        fields :name, :locales, :default_locale

        field :header_title do |portal|
          portal.header_tagline.presence || portal.name
        end

        field :header_tagline do |portal|
          portal.header_tagline
        end

        field :hero_title do |portal|
          portal.hero_title.presence || "How can we help?"
        end

        field :hero_subtitle do |portal|
          portal.hero_subtitle.presence || "Search our documentation and guides"
        end

        field :categories_count do |portal|
          portal.categories.where(visibility: :everyone).count
        end

        field :articles_count do |portal|
          portal.articles.published.where(visibility: :everyone).count
        end

        field :logo_url do |portal|
          if portal.logo.attached?
            Rails.application.routes.url_helpers.rails_blob_url(portal.logo, only_path: true)
          end
        end
      end
    end
  end
end
