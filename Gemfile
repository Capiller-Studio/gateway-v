# frozen_string_literal: true

source "https://rubygems.org"

ruby "4.0.6"

gem "rails", ">= 8.1.3"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "dotenv-rails"

# Unique to Gateway (API Layer)
gem 'grape'
gem 'blueprinter'
gem 'jwt'
gem 'rack-cors'

group :development, :test do
  gem 'pry'
  gem 'pry-rails'
  gem 'awesome_print'
  gem 'factory_bot_rails'
  gem 'ffaker'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'database_cleaner-active_record'
  gem 'timecop'
  gem 'pundit-matchers'
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
