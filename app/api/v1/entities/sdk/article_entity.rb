# frozen_string_literal: true

module V1
  module Entities
    module Sdk
      class ArticleEntity < Blueprinter::Base
        identifier :id

        fields :slug, :title, :article_type, :position, :views_count, :updated_at

        field :description do |article|
          article.meta_description
        end

        field :banner_image_url do |article|
          if article.banner_image.attached?
            Rails.application.routes.url_helpers.rails_blob_url(article.banner_image, only_path: true)
          end
        end

        field :estimated_read_time do |article|
          article.stats&.dig("estimated_read_time") || 1
        end

        field :content, if: ->(_field_name, _article, options) { options[:full_content] }

        field :category do |article|
          cat = article.primary_category
          if cat
            {
              id: cat.id,
              name: cat.name,
              slug: cat.slug
            }
          end
        end

        field :author, if: ->(_field_name, _article, options) { options[:full_content] } do |article|
          user = article.author
          if user
            avatar = Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: true) if user.avatar.attached?

            {
              name: user.name.presence || user.display_name,
              avatar_url: avatar
            }
          end
        end

        field :reactions, if: ->(_field_name, _article, options) { options[:full_content] } do |article|
          {
            happy: article.article_reactions.happy.count,
            neutral: article.article_reactions.neutral.count,
            sad: article.article_reactions.sad.count
          }
        end
      end
    end
  end
end
