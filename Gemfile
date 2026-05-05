# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.4.1"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bootsnap", require: false

# Unique to Gateway (API Layer)
gem 'grape'
gem 'blueprinter'
gem 'jwt'
gem 'rack-cors'
gem "solid_cache"
gem "solid_queue"

group :development, :test do
  gem 'dotenv-rails'
  gem 'pry'
  gem 'pry-rails'
  gem 'awesome_print'
  gem 'factory_bot_rails'
  gem 'ffaker'
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem 'annotate'
  gem 'bullet'
end

# ============================================================================
# Shared Backend (Core)
# ============================================================================
gem 'core', path: "../core"
