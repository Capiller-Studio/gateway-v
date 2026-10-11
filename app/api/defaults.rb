# frozen_string_literal: true

require_relative 'v1/validators/password_format'

module Defaults
  extend ActiveSupport::Concern

  SUPPORTED_LOCALES = Core::SUPPORTED_LOCALES

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

      def detect_locale
        raw_locale = params[:locale] || headers['X-Locale'] || env['HTTP_X_LOCALE'] || env['HTTP_ACCEPT_LANGUAGE']
        return I18n.default_locale if raw_locale.blank?

        normalized = raw_locale.to_s.split(',').first.to_s.strip.split(';').first.to_s.strip.tr('_', '-')

        return :'pt-BR' if normalized.casecmp('pt').zero? || normalized.casecmp('pt-br').zero? || normalized.downcase.start_with?('pt-')

        base = normalized.split('-').first.downcase.to_sym
        return base if SUPPORTED_LOCALES.include?(base)

        I18n.default_locale
      end
    end

    before do
      I18n.locale = detect_locale
    end

    after do
      I18n.locale = I18n.default_locale
    end

    rescue_from ActiveRecord::RecordNotFound do |_e|
      error!({ success: false, errors: [{ code: "not_found", message: I18n.t("gateway.errors.not_found", default: "Resource not found") }] }, 404)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      errors = e.record.errors.map { |err| { code: "record_invalid", field: err.attribute.to_s, message: err.full_message } }
      error!({ success: false, errors: errors }, 422)
    end

    rescue_from Grape::Exceptions::ValidationErrors do |e|
      errors = e.errors.map { |attrs, msgs| { code: "validation_error", field: attrs.first.to_s, message: msgs.first } }
      error!({ success: false, errors: errors }, 422)
    end

    rescue_from :all do |e|
      if Rails.env.development?
        raise e
      else
        Rails.logger.error "Unhandled error: #{e.class} — #{e.message}\n#{e.backtrace&.first(15)&.join("\n")}"
        error!({ success: false, errors: [{ code: "internal_error", message: I18n.t("gateway.errors.internal_error", default: "Internal server error") }] }, 500)
      end
    end
  end
end

