# frozen_string_literal: true

module V1
  module Resources
    module Sdk
      class HelpCenter < Grape::API
        resource :help_center do
          helpers do
            def find_active_portal!
              authenticate_sdk_channel!

              channel = current_channel
              unless channel.help_center_enabled? && channel.portal.present?
                error!({ success: false, errors: [{ code: 'help_center_disabled', message: 'Help Center is not enabled for this channel' }] }, 404)
              end

              channel.portal
            end
          end

          desc 'Get Help Center portal metadata'
          params do
            optional :locale, type: String, desc: 'Requested language locale (e.g. en, es, fr)'
          end
          get do
            portal = find_active_portal!

            portal_data = with_sdk_shard do
              with_sdk_locale(fallback: portal.default_locale) do
                V1::Entities::Sdk::PortalEntity.render_as_hash(portal)
              end
            end

            success(data: portal_data)
          end

          desc 'List published categories'
          params do
            optional :locale, type: String, desc: 'Requested language locale (e.g. en, es, fr)'
          end
          get :categories do
            portal = find_active_portal!

            categories_data = with_sdk_shard do
              with_sdk_locale(fallback: portal.default_locale) do
                categories = portal.categories.where(visibility: :everyone).order(:position).preload(:translations)
                V1::Entities::Sdk::CategoryEntity.render_as_hash(categories)
              end
            end

            success(data: categories_data)
          end

          desc 'Get category details and its articles'
          params do
            requires :id, type: String, desc: 'Category UUID or slug'
            optional :locale, type: String, desc: 'Requested language locale (e.g. en, es, fr)'
          end
          get 'categories/:id' do
            portal = find_active_portal!

            category_data = with_sdk_shard do
              with_sdk_locale(fallback: portal.default_locale) do
                category = if params[:id].match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
                  portal.categories.where(visibility: :everyone).preload(:translations).find_by(id: params[:id])
                else
                  portal.categories.where(visibility: :everyone).joins(:translations).preload(:translations).find_by(help_center_category_translations: { slug: params[:id] })
                end

                unless category
                  error!({ success: false, errors: [{ code: 'not_found', message: 'Category not found' }] }, 404)
                end

                V1::Entities::Sdk::CategoryEntity.render_as_hash(category, include_articles: true)
              end
            end

            success(data: category_data)
          end

          desc 'List published articles with pagination'
          params do
            optional :category_id, type: String, desc: 'Filter by category UUID or slug'
            optional :locale, type: String, desc: 'Requested language locale (e.g. en, es, fr)'
            optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
            optional :per_page, type: Integer, default: 20, values: 1..100
          end
          get :articles do
            portal = find_active_portal!

            articles_data, meta = with_sdk_shard do
              with_sdk_locale(fallback: portal.default_locale) do
                scope = portal.articles.published.where(visibility: :everyone).order(:position).preload(:translations, :primary_category)

                if params[:category_id].present?
                  cat = if params[:category_id].match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
                    portal.categories.find_by(id: params[:category_id])
                  else
                    portal.categories.joins(:translations).find_by(help_center_category_translations: { slug: params[:category_id] })
                  end

                  if cat
                    scope = scope.where(
                      "help_center_articles.id IN (SELECT resource_id FROM help_center_category_resources WHERE category_id = :cat_id AND resource_type = 'HelpCenter::Article') OR help_center_articles.primary_category_id = :cat_id",
                      cat_id: cat.id
                    )
                  else
                    scope = scope.none
                  end
                end

                records, meta_info = paginate(scope, page: params[:page], per_page: params[:per_page])
                [V1::Entities::Sdk::ArticleEntity.render_as_hash(records), meta_info]
              end
            end

            success(
              data: {
                articles: articles_data,
                pagination: {
                  page: meta[:current_page],
                  current_page: meta[:current_page],
                  per_page: meta[:per_page],
                  total_count: meta[:total_count],
                  total_pages: meta[:total_pages]
                }
              }
            )
          end

          desc 'Get full article details'
          params do
            requires :id, type: String, desc: 'Article UUID or slug'
            optional :locale, type: String, desc: 'Requested language locale (e.g. en, es, fr)'
          end
          get 'articles/:id' do
            portal = find_active_portal!

            article_data = with_sdk_shard do
              with_sdk_locale(fallback: portal.default_locale) do
                scope = portal.articles.published.where(visibility: :everyone).preload(:translations, :primary_category)

                article = if params[:id].match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
                  scope.find_by(id: params[:id])
                else
                  scope.joins(:translations).find_by(help_center_article_translations: { slug: params[:id] })
                end

                unless article
                  error!({ success: false, errors: [{ code: 'not_found', message: 'Article not found' }] }, 404)
                end

                # Increment views count silently
                ::HelpCenter::Article.increment_counter(:views_count, article.id, touch: false) rescue nil

                V1::Entities::Sdk::ArticleEntity.render_as_hash(article.reload, full_content: true)
              end
            end

            success(data: article_data)
          end

          desc 'Search Help Center articles'
          params do
            requires :q, type: String, desc: 'Search query'
            optional :locale, type: String, desc: 'Requested language locale (e.g. en, es, fr)'
            optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
            optional :per_page, type: Integer, default: 20, values: 1..100
          end
          get :search do
            portal = find_active_portal!
            query = params[:q].to_s.strip

            if query.blank?
              return success(
                data: {
                  articles: [],
                  pagination: {
                    page: params[:page],
                    current_page: params[:page],
                    per_page: params[:per_page],
                    total_count: 0,
                    total_pages: 1
                  }
                }
              )
            end

            articles_data, meta = with_sdk_shard do
              with_sdk_locale(fallback: portal.default_locale) do
                active_locales = [I18n.locale.to_s, portal.default_locale.to_s].uniq

                sql_scope = portal.articles.published.where(visibility: :everyone)
                                  .joins(:translations)
                                  .where(help_center_article_translations: { locale: active_locales })
                                  .where(
                                    'help_center_article_translations.title ILIKE :q OR help_center_article_translations.content ILIKE :q',
                                    q: "%#{query}%"
                                  )
                                  .distinct
                                  .order(:position)

                # Fallback to searching all translations if no matches found in active locale
                if sql_scope.empty?
                  sql_scope = portal.articles.published.where(visibility: :everyone)
                                    .joins(:translations)
                                    .where(
                                      'help_center_article_translations.title ILIKE :q OR help_center_article_translations.content ILIKE :q',
                                      q: "%#{query}%"
                                    )
                                    .distinct
                                    .order(:position)
                end

                records, meta_info = paginate(sql_scope, page: params[:page], per_page: params[:per_page])
                [V1::Entities::Sdk::ArticleEntity.render_as_hash(records), meta_info]
              end
            end

            success(
              data: {
                articles: articles_data,
                pagination: {
                  page: meta[:current_page],
                  current_page: meta[:current_page],
                  per_page: meta[:per_page],
                  total_count: meta[:total_count],
                  total_pages: meta[:total_pages]
                }
              }
            )
          end

          desc 'Submit feedback reaction for an article'
          params do
            requires :id, type: String, desc: 'Article UUID or slug'
            requires :reaction_type, type: String, values: %w[happy neutral sad 0 1 2], desc: 'Reaction sentiment'
          end
          post 'articles/:id/reactions' do
            portal = find_active_portal!

            sentiment = case params[:reaction_type].to_s
            when '0', 'happy' then :happy
            when '1', 'neutral' then :neutral
            when '2', 'sad' then :sad
            else :happy
            end

            reaction_counts = with_sdk_shard do
              scope = portal.articles.published.where(visibility: :everyone)

              article = if params[:id].match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
                scope.find_by(id: params[:id])
              else
                scope.joins(:translations).find_by(help_center_article_translations: { slug: params[:id] })
              end

              unless article
                error!({ success: false, errors: [{ code: 'not_found', message: 'Article not found' }] }, 404)
              end

              reaction = article.article_reactions.find_or_initialize_by(
                ip_address: request.ip
              )
              reaction.reaction_type = sentiment
              reaction.save!

              {
                happy: article.article_reactions.happy.count,
                neutral: article.article_reactions.neutral.count,
                sad: article.article_reactions.sad.count
              }
            end

            status 201
            success(
              data: {
                message: 'Reaction recorded successfully',
                reactions: reaction_counts
              }
            )
          end
        end
      end
    end
  end
end
