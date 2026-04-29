source "https://rubygems.org"

ruby "3.4.1"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"

# Shared backend
gem 'core', path: "../core"

# The high-performance API framework
gem 'grape'
gem 'grape-entity'

# Ultra-fast serialization
gem 'blueprinter'

# High-speed JSON parsing/generation
gem 'oj'

# Authentication
gem 'jwt'

# Efficient pagination
gem 'pagy', '~> 6.2'

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# CORS for cross-origin APIs
gem 'rack-cors'

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end
