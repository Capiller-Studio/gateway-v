# frozen_string_literal: true

module V1
  module Entities
    module Sdk
      class CategoryEntity < Blueprinter::Base
        identifier :id

        fields :slug, :name, :description, :icon_key, :position

        field :image_url do |category|
          if category.image.attached?
            Rails.application.routes.url_helpers.rails_blob_url(category.image, only_path: true)
          end
        end

        field :articles_count do |category|
          category.portal.articles.published.where(visibility: :everyone)
                  .where(
                    "help_center_articles.id IN (SELECT resource_id FROM help_center_category_resources WHERE category_id = :cat_id AND resource_type = 'HelpCenter::Article') OR help_center_articles.primary_category_id = :cat_id",
                    cat_id: category.id
                  ).count
        end

        field :articles, if: ->(_field_name, _category, options) { options[:include_articles] } do |category|
          articles_scope = category.portal.articles.published.where(visibility: :everyone)
                                   .where(
                                     "help_center_articles.id IN (SELECT resource_id FROM help_center_category_resources WHERE category_id = :cat_id AND resource_type = 'HelpCenter::Article') OR help_center_articles.primary_category_id = :cat_id",
                                     cat_id: category.id
                                   ).order(:position)
          V1::Entities::Sdk::ArticleEntity.render_as_hash(articles_scope)
        end
      end
    end
  end
end
