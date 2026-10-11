# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Sdk Pre-Chat Form and HelpCenter', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let!(:plan) do
    create(:plan, features: { 'channels' => { 'mobile_widget' => true } }, limits: { 'channels' => 100, 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  let!(:domain) { create(:domain, account: account) }
  let!(:portal) do
    account.with_shard do
      create(:help_center_portal, account: account, domain: domain, name: 'Mobile Help Center', default_locale: 'en', locales: %w[en es])
    end
  end

  let!(:category) do
    account.with_shard do
      cat = create(:help_center_category, account: account, portal: portal, position: 1)
      trans_en = cat.translations.find_or_initialize_by(locale: 'en')
      trans_en.name = 'Billing & Plans'
      trans_en.slug = 'billing-plans'
      trans_en.description = 'Billing and subscription guides'
      trans_en.save!

      trans_es = cat.translations.find_or_initialize_by(locale: 'es')
      trans_es.name = 'Facturación y Planes'
      trans_es.slug = 'facturacion-y-planes'
      trans_es.description = 'Guías sobre pagos y planes'
      trans_es.save!
      cat
    end
  end

  let!(:article) do
    account.with_shard do
      art = create(:help_center_article, account: account, portal: portal, primary_category: category, status: :published, visibility: :everyone, title: 'How to update billing', slug: 'how-to-update-billing')
      trans_en = art.translations.find_or_initialize_by(locale: 'en')
      trans_en.title = 'How to update billing'
      trans_en.content = 'Go to your account settings and select billing.'
      trans_en.slug = 'how-to-update-billing'
      trans_en.meta_description = 'Billing guide'
      trans_en.save!

      trans_es = art.translations.find_or_initialize_by(locale: 'es')
      trans_es.title = 'Cómo actualizar la facturación'
      trans_es.content = 'Vaya a la configuración de su cuenta y seleccione facturación.'
      trans_es.slug = 'como-actualizar-la-facturacion'
      trans_es.meta_description = 'Guía de facturación'
      trans_es.save!

      HelpCenter::CategoryResource.find_or_create_by!(category: category, resource: art)
      art
    end
  end

  let!(:custom_pre_chat_form) do
    account.with_shard do
      form = create(:channel_contact_form, account: account, name: 'Custom Pre-Chat Form', title: 'Start a Chat', subtitle: 'Please fill in details')
      form.translations.find_or_create_by!(locale: 'es') do |t|
        t.title = 'Iniciar una conversación'
        t.subtitle = 'Por favor complete sus datos'
        t.submit_button_text = 'Comenzar Chat'
      end
      form
    end
  end

  let!(:channel) do
    account.with_shard do
      ch = create(:channel_mobile_widget, account: account, name: 'Mobile Support')
      ch.portal = portal
      ch.help_center_enabled = true
      ch.pre_chat_form_enabled = true
      ch.translations.find_or_create_by!(locale: 'es') do |t|
        t.header_title = 'Soporte Móvil'
        t.welcome_title = '¡Bienvenido!'
        t.welcome_tagline = '¿En qué podemos ayudarle?'
        t.pre_chat_title = 'Iniciar Chat'
        t.pre_chat_subtitle = 'Introduzca sus datos'
      end
      ch.save!
      ch
    end
  end

  let!(:inbox) do
    account.with_shard do
      create(:inbox, account: account, channel: channel, primary_inbox: true, name: 'Mobile Support Inbox')
    end
  end

  let(:sdk_headers) do
    { 'X-Deskbolic-App-Id' => channel.identifier }
  end

  before do
    Rails.cache.clear
  end

  describe 'GET /v1/sdk/forms/pre_chat' do
    context 'when pre-chat form is enabled with default fallback fields' do
      it 'returns default name and email fields structured as CustomFieldEntity' do
        get '/v1/sdk/forms/pre_chat', headers: sdk_headers

        expect(response).to have_http_status(:ok)
        expect(json_response['success']).to be true
        data = json_response['data']
        expect(data['enabled']).to be true
        expect(data['fields'].size).to eq(2)
        expect(data['fields'].map { |f| f['key'] }).to eq(%w[name email])

        name_field = data['fields'].find { |f| f['key'] == 'name' }
        expect(name_field['entity_type']).to eq('customer')
        expect(name_field['field_type']).to eq('text')
        expect(name_field['required']).to be true
        expect(name_field['position']).to eq(1)

        email_field = data['fields'].find { |f| f['key'] == 'email' }
        expect(email_field['entity_type']).to eq('customer')
        expect(email_field['field_type']).to eq('email')
        expect(email_field['required']).to be true
        expect(email_field['position']).to eq(2)
      end
    end

    context 'when pre-chat form is linked to a custom contact form' do
      before do
        account.with_shard do
          name_cf = account.custom_fields.find_or_create_by!(key: 'full_name') do |cf|
            cf.label = 'Full Name'
            cf.field_type = 'text'
            cf.entity_type = 'customer'
          end
          create(:custom_field_resource, resource: custom_pre_chat_form, custom_field: name_cf, position: 1)
          channel.update!(pre_chat_form: custom_pre_chat_form)
        end
      end

      it 'returns custom fields with entity_type and CustomFieldEntity schema' do
        get '/v1/sdk/forms/pre_chat', headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['enabled']).to be true
        first_field = data['fields'].first
        expect(first_field['key']).to eq('full_name')
        expect(first_field['label']).to eq('Full Name')
        expect(first_field['entity_type']).to eq('customer')
        expect(first_field['field_type']).to eq('text')
        expect(first_field).to have_key('options')
        expect(first_field).to have_key('validations')
      end

      it 'returns localized form strings and options when locale is passed' do
        get '/v1/sdk/forms/pre_chat', params: { locale: 'es' }, headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['locale']).to eq('es')
        expect(data['title']).to eq('Iniciar una conversación')
        expect(data['submit_button_text']).to eq('Comenzar Chat')
      end
    end

    context 'when pre-chat form is disabled even if pre_chat_form association is present' do
      before do
        account.with_shard { channel.update!(pre_chat_form_enabled: false, pre_chat_form: custom_pre_chat_form) }
      end

      it 'returns enabled false and empty fields' do
        get '/v1/sdk/forms/pre_chat', headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['enabled']).to be false
        expect(data['fields']).to be_empty
      end

      it 'returns pre_chat_form_enabled false in /v1/sdk/config' do
        get '/v1/sdk/config', headers: sdk_headers

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['features']['pre_chat_form_enabled']).to be false
      end
    end
  end

  describe 'Help Center APIs & Internationalization' do
    describe 'GET /v1/sdk/help_center' do
      it 'returns portal metadata' do
        get '/v1/sdk/help_center', headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['id']).to eq(portal.id)
        expect(data['name']).to eq('Mobile Help Center')
        expect(data['locales']).to include('en', 'es')
        expect(data['default_locale']).to eq('en')
        expect(data['categories_count']).to be >= 1
        expect(data['articles_count']).to be >= 1
      end

      it 'returns 404 when help center is disabled on channel' do
        account.with_shard { channel.update!(help_center_enabled: false) }

        get '/v1/sdk/help_center', headers: sdk_headers

        expect(response).to have_http_status(:not_found)
        expect(json_response['errors'].first['code']).to eq('help_center_disabled')
      end
    end

    describe 'GET /v1/sdk/help_center/categories' do
      it 'lists categories in default locale' do
        get '/v1/sdk/help_center/categories', headers: sdk_headers

        expect(response).to have_http_status(:ok)
        categories = json_response['data']
        expect(categories).to be_an(Array)
        expect(categories.first['id']).to eq(category.id)
        expect(categories.first['name']).to eq('Billing & Plans')
        expect(categories.first['slug']).to eq('billing-plans')
      end

      it 'lists categories in requested locale (Spanish)' do
        get '/v1/sdk/help_center/categories', params: { locale: 'es' }, headers: sdk_headers

        expect(response).to have_http_status(:ok)
        categories = json_response['data']
        expect(categories.first['name']).to eq('Facturación y Planes')
        expect(categories.first['slug']).to eq('facturacion-y-planes')
      end
    end

    describe 'GET /v1/sdk/help_center/categories/:id' do
      it 'returns category details and its articles' do
        get "/v1/sdk/help_center/categories/#{category.id}", headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['id']).to eq(category.id)
        expect(data['name']).to eq('Billing & Plans')
        expect(data['articles']).to be_an(Array)
        expect(data['articles'].first['id']).to eq(article.id)
      end

      it 'resolves category by translated Spanish slug' do
        get '/v1/sdk/help_center/categories/facturacion-y-planes', params: { locale: 'es' }, headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['id']).to eq(category.id)
        expect(data['name']).to eq('Facturación y Planes')
        expect(data['articles'].first['title']).to eq('Cómo actualizar la facturación')
      end

      it 'returns 404 for non-existent category' do
        get "/v1/sdk/help_center/categories/#{SecureRandom.uuid}", headers: sdk_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET /v1/sdk/help_center/articles' do
      it 'lists published articles in default locale' do
        get '/v1/sdk/help_center/articles', headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['articles']).to be_an(Array)
        expect(data['articles'].first['id']).to eq(article.id)
        expect(data['articles'].first['title']).to eq('How to update billing')
        expect(data['pagination']['total_count']).to be >= 1
      end

      it 'lists published articles in requested locale (Spanish)' do
        get '/v1/sdk/help_center/articles', params: { locale: 'es' }, headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['articles'].first['title']).to eq('Cómo actualizar la facturación')
      end

      it 'filters by category_id' do
        get '/v1/sdk/help_center/articles', params: { category_id: category.id }, headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['articles'].size).to eq(1)
        expect(data['articles'].first['id']).to eq(article.id)
      end
    end

    describe 'GET /v1/sdk/help_center/articles/:id' do
      it 'returns full article details in default locale and increments view count' do
        initial_views = article.views_count

        get "/v1/sdk/help_center/articles/#{article.id}", headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['id']).to eq(article.id)
        expect(data['title']).to eq('How to update billing')
        expect(data['content']).to include('Go to your account settings')
        expect(data['reactions']).to include('happy', 'neutral', 'sad')

        expect(article.reload.views_count).to be >= initial_views + 1
      end

      it 'resolves article by translated Spanish slug and returns Spanish content' do
        get '/v1/sdk/help_center/articles/como-actualizar-la-facturacion', params: { locale: 'es' }, headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['id']).to eq(article.id)
        expect(data['title']).to eq('Cómo actualizar la facturación')
        expect(data['content']).to include('Vaya a la configuración de su cuenta')
      end

      it 'returns 404 for non-existent article' do
        get "/v1/sdk/help_center/articles/#{SecureRandom.uuid}", headers: sdk_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET /v1/sdk/help_center/search' do
      it 'searches articles matching query in English' do
        get '/v1/sdk/help_center/search', params: { q: 'billing' }, headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['articles']).to be_an(Array)
        expect(data['articles'].map { |a| a['id'] }).to include(article.id)
        expect(data['articles'].first['title']).to eq('How to update billing')
      end

      it 'searches articles matching query in Spanish' do
        get '/v1/sdk/help_center/search', params: { q: 'facturación', locale: 'es' }, headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['articles'].map { |a| a['id'] }).to include(article.id)
        expect(data['articles'].first['title']).to eq('Cómo actualizar la facturación')
      end

      it 'returns empty results for non-matching query' do
        get '/v1/sdk/help_center/search', params: { q: 'xyznonsensequery123' }, headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['articles']).to be_empty
      end

      it 'returns empty results for blank query' do
        get '/v1/sdk/help_center/search', params: { q: '   ' }, headers: sdk_headers

        expect(response).to have_http_status(:ok)
        data = json_response['data']
        expect(data['articles']).to be_empty
      end
    end

    describe 'POST /v1/sdk/help_center/articles/:id/reactions' do
      it 'submits happy reaction' do
        post "/v1/sdk/help_center/articles/#{article.id}/reactions", params: { reaction_type: 'happy' }, headers: sdk_headers

        expect(response).to have_http_status(:created)
        expect(json_response['success']).to be true
        expect(json_response['data']['reactions']['happy']).to eq(1)

        account.with_shard do
          reaction = HelpCenter::ArticleReaction.find_by(article: article)
          expect(reaction).to be_present
          expect(reaction).to be_happy
        end
      end

      it 'returns 404 for non-existent article' do
        post "/v1/sdk/help_center/articles/#{SecureRandom.uuid}/reactions", params: { reaction_type: 'happy' }, headers: sdk_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
