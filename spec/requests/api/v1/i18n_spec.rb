# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gateway API Internationalization (i18n)', type: :request do
  describe 'Localization of unauthorized error responses' do
    it 'returns English message by default' do
      get '/v1/me'

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['errors'].first['message']).to eq('Authentication required')
    end

    it 'returns Arabic message when Accept-Language is ar' do
      get '/v1/me', headers: { 'Accept-Language' => 'ar' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['errors'].first['message']).to eq('المصادقة مطلوبة')
    end

    it 'returns German message when X-Locale is de' do
      get '/v1/me', headers: { 'X-Locale' => 'de' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['errors'].first['message']).to eq('Authentifizierung erforderlich')
    end

    it 'returns Spanish message when locale param is es' do
      get '/v1/me', params: { locale: 'es' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['errors'].first['message']).to eq('Autenticación requerida')
    end

    it 'returns French message when Accept-Language is fr-FR' do
      get '/v1/me', headers: { 'Accept-Language' => 'fr-FR,fr;q=0.9' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['errors'].first['message']).to eq('Authentification requise')
    end

    it 'returns Korean message when X-Locale is ko' do
      get '/v1/me', headers: { 'X-Locale' => 'ko' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['errors'].first['message']).to eq('인증이 필요합니다')
    end

    it 'returns Portuguese (Brazil) message when locale is pt or pt-BR' do
      get '/v1/me', headers: { 'Accept-Language' => 'pt-BR' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['errors'].first['message']).to eq('Autenticação necessária')

      get '/v1/me', params: { locale: 'pt' }
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['errors'].first['message']).to eq('Autenticação necessária')
    end
  end
end
