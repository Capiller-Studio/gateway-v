# frozen_string_literal: true

module V1
  module Resources
    module Sdk
      class Config < Grape::API
        resource :config do
          desc 'Get Mobile Widget configuration and appearance'
          params do
            optional :locale, type: String, desc: 'Requested language locale (e.g. en, es, fr)'
          end
          get do
            authenticate_sdk_channel!

            channel = current_channel
            inbox = current_inbox

            is_offline = if inbox&.business_hour_group_id.present?
              !::AssignmentPolicies::BusinessHoursChecker.call(
                business_hour_group: inbox.business_hour_group,
                time: Time.current
              )
            else
              false
            end

            with_sdk_shard do
              with_sdk_locale do
                active_locale = I18n.locale.to_s

                success(
                  data: {
                    app_id: channel.identifier,
                    name: channel.name,
                    locale: active_locale,
                    default_locale: channel.default_locale.presence || 'en',
                    locales: channel.locales.presence || ['en'],
                    header_title: channel.header_title.presence || channel.name,
                    welcome_title: channel.welcome_title.presence || "Welcome!",
                    welcome_tagline: channel.welcome_tagline.presence || "How can we help you today?",
                    reply_time_text: channel.reply_time_text.presence || "We typically reply within a few minutes",
                    features: {
                      anonymous_allowed: channel.anonymous_allowed?,
                      secure_identity_enforced: channel.secure_identity_enforced?,
                      attachments_enabled: channel.attachments_enabled?,
                      max_attachment_mb: (channel.max_attachment_mb.presence || 20).to_i,
                      help_center_enabled: channel.help_center_enabled?,
                      portal_id: channel.portal_id,
                      pre_chat_form_enabled: channel.pre_chat_form_enabled?,
                      custom_branding: channel.custom_branding?
                    },
                    theme: {
                      primary_color: channel.ui_configurations&.dig("primary_color").presence || channel.theme_color.presence || "#4F46E5",
                      header_title_color: channel.header_title_color.presence || "#FFFFFF"
                    },
                    is_online: !is_offline
                  }
                )
              end
            end
          end
        end
      end
    end
  end
end
