# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Resources::System', type: :request do
  describe 'GET /v1/system/config' do
    it 'returns system configurations, versions, and supported locales' do
      get '/v1/system/config'

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['api_version']).to eq('1.0.0')
      expect(json_response['data']['supported_locales']).to include('en', 'ar', 'de', 'es', 'fr', 'ko', 'pt-BR')
      expect(json_response['data']['default_locale']).to eq('en')
      expect(json_response['data']['action_cable_url']).to be_present
    end
  end
end
