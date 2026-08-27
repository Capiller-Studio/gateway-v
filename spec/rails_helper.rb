# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'shoulda/matchers'
require 'database_cleaner/active_record'
require 'factory_bot_rails'
require 'ffaker'
require 'timecop'
require 'pundit/matchers'

FactoryBot.definition_file_paths = [
  Core::Engine.root.join('spec/factories'),
  Rails.root.join('spec/factories')
]
FactoryBot.find_definitions if FactoryBot.factories.count.zero?

ActiveRecord::Encryption.configure(
  primary_key: 'test_primary_key_for_rspec_testing',
  deterministic_key: 'test_deterministic_key_for_rspec',
  key_derivation_salt: 'test_key_derivation_salt_rspec'
)

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

module ApiRequestHelpers
  def auth_headers(user, account: nil)
    token = JwtService.encode({ user_id: user.id })
    account_id = account&.id || user.accounts.first&.id
    {
      'Authorization' => "Bearer #{token}",
      'X-Account-Id' => account_id
    }
  end

  def mobile_headers(additional = {})
    secret = Rails.application.credentials.dig(Rails.env.to_sym, :mobile_app_secret) ||
             Rails.application.credentials.dig(:mobile_app_secret) ||
             ENV['MOBILE_APP_SECRET'] ||
             'dev_mobile_secret_123'

    { 'X-Mobile-App-Secret' => secret }.merge(additional)
  end

  def json_response
    JSON.parse(response.body).with_indifferent_access
  rescue StandardError
    {}
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.include FactoryBot::Syntax::Methods
  config.include ApiRequestHelpers, type: :request

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Searchkick.disable_callbacks if defined?(Searchkick)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :feature) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
