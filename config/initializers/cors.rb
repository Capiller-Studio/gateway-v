# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*" # TODO: Restrict to specific domains in production

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["X-Total-Count", "X-Per-Page", "X-Page", "X-Request-Id"],
      max_age: 7200
  end
end
