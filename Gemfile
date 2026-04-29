source "https://rubygems.org"

ruby "3.4.1"

gem "rails", "~> 8.1.3"

# Shared backend engine
gem 'core', path: "../core"

# --- API Framework ---
gem 'grape'

# --- Serialization ---
gem 'blueprinter'
gem 'oj'

# --- Authentication ---
gem 'jwt'

# --- Pagination ---
gem 'pagy', '~> 6.2'

# --- Security ---
gem 'rack-cors'
gem 'rack-attack'

# --- Infrastructure ---
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "solid_cache"
gem "solid_queue"
gem "bootsnap", require: false
gem "image_processing", "~> 1.2"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end
