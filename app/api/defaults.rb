# frozen_string_literal: true

module Defaults
  extend ActiveSupport::Concern

  included do
    format :json
    formatter :json, Grape::Formatter::Oj

    helpers V1::Helpers::AuthHelpers
    helpers V1::Helpers::AuthorizationHelpers
    helpers V1::Helpers::ResponseHelpers

    helpers do
      def logger
        Rails.logger
      end
    end

    before do
      locale = params[:locale] || env['HTTP_X_LOCALE'] || headers['X-Locale'] || env['HTTP_ACCEPT_LANGUAGE']&.scan(/^[a-z]{2}/)&.first
      I18n.locale = if locale.present? && I18n.available_locales.include?(locale.to_sym)
                      locale.to_sym
                    else
                      I18n.default_locale
                    end
    end

    rescue_from ActiveRecord::RecordNotFound do |_e|
      error_response(message: { error: I18n.t("gateway.errors.not_found", default: "Resource not found") }, status: 404)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      errors = e.record.errors.map { |err| { field: err.attribute.to_s, message: err.full_message } }
      error_response(message: { errors: errors }, status: 422)
    end

    rescue_from Grape::Exceptions::ValidationErrors do |e|
      errors = e.errors.map { |attrs, msgs| { field: attrs.first.to_s, message: msgs.first } }
      error_response(message: { errors: errors }, status: 422)
    end

    rescue_from :all do |e|
      if Rails.env.development?
        raise e
      else
        Rails.logger.error "Unhandled error: #{e.class} — #{e.message}"
        error_response(message: { error: I18n.t("gateway.errors.internal_error", default: "Internal server error") }, status: 500)
      end
    end
  end
end
