# frozen_string_literal: true

module Defaults
    extend ActiveSupport::Concern

    included do
      prefix "api"
      format :json
      formatter :json, Grape::Formatter::Oj

      helpers do
        def logger
          Rails.logger
        end
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        error_response(message: e.message, status: 404)
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        error_response(message: e.message, status: 422)
      end

      rescue_from :all do |e|
        if Rails.env.development?
          raise e
        else
          error_response(message: "Internal Server Error", status: 500)
        end
      end
    end
  end
end
