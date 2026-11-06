# frozen_string_literal: true

module V1
  module Resources
    class System < Grape::API
      resource :system do
        desc 'Get system configuration, supported versions, and feature flags'
        get :config do
          cable_url = ENV['ACTION_CABLE_URL'].presence || 'wss://ws-rely.capiller.com'
          success(
            data: {
              api_version: '1.0.0',
              min_supported_mobile_version: '1.0.0',
              latest_mobile_version: '1.0.0',
              supported_locales: Core::SUPPORTED_LOCALES.map(&:to_s),
              default_locale: I18n.default_locale.to_s,
              current_locale: I18n.locale.to_s,
              action_cable_url: cable_url,
              maintenance_mode: false
            }
          )
        end
      end
    end
  end
end
