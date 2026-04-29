# frozen_string_literal: true

module Defaults
  extend ActiveSupport::Concern

  included do
    prefix "api"
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

    rescue_from ActiveRecord::RecordNotFound do |_e|
      error_response(message: { error: "Resource not found" }, status: 404)
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
        error_response(message: { error: "Internal server error" }, status: 500)
      end
    end
  end
end
