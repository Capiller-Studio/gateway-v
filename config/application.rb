require_relative "boot"

require "rails"
# Only load frameworks the gateway actually needs
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module Gateway
  class Application < Rails::Application
    config.load_defaults 8.0

    config.api_only = true
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore
    config.middleware.use Rack::Attack

    # Autoload Grape API handled by Zeitwerk by default in Rails 7+
  end
end
