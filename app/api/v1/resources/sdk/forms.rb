# frozen_string_literal: true

module V1
  module Resources
    module Sdk
      class Forms < Grape::API
        resource :forms do
          desc 'Get Pre-Chat form schema and dynamic fields'
          params do
            optional :locale, type: String, desc: 'Requested language locale (e.g. en, es, fr)'
          end
          get :pre_chat do
            authenticate_sdk_channel!

            channel = current_channel

            with_sdk_shard do
              with_sdk_locale do
                active_locale = I18n.locale.to_s
                form = channel.pre_chat_form

                title = form&.title.presence || channel.pre_chat_title.presence || I18n.t('sdk.pre_chat.title', default: 'Start a Conversation')
                subtitle = form&.subtitle.presence || channel.pre_chat_subtitle.presence || I18n.t('sdk.pre_chat.subtitle', default: 'Please introduce yourself to start chatting with our team')
                submit_button_text = form&.submit_button_text.presence || I18n.t('sdk.pre_chat.submit', default: 'Start Chat')

                unless channel.pre_chat_form_enabled?
                  return success(
                    data: {
                      enabled: false,
                      title: title,
                      subtitle: subtitle,
                      submit_button_text: submit_button_text,
                      locale: active_locale,
                      fields: []
                    }
                  )
                end

                fields_data = if form.present? && form.custom_field_resources.any?
                  resources = form.custom_field_resources.order(:position).includes(custom_field: :translations)
                  V1::Entities::Sdk::CustomFieldEntity.render_as_hash(resources, locale: I18n.locale)
                else
                  fallback_fields = [
                    {
                      key: 'name',
                      label: I18n.t('sdk.pre_chat.name', default: 'Name'),
                      placeholder: I18n.t('sdk.pre_chat.name_placeholder', default: 'Enter your full name'),
                      field_type: 'text',
                      entity_type: 'customer',
                      required: true,
                      position: 1,
                      options: [],
                      validations: {}
                    },
                    {
                      key: 'email',
                      label: I18n.t('sdk.pre_chat.email', default: 'Email'),
                      placeholder: I18n.t('sdk.pre_chat.email_placeholder', default: 'name@example.com'),
                      field_type: 'email',
                      entity_type: 'customer',
                      required: true,
                      position: 2,
                      options: [],
                      validations: {}
                    }
                  ]
                  V1::Entities::Sdk::CustomFieldEntity.render_as_hash(fallback_fields, locale: I18n.locale)
                end

                success(
                  data: {
                    enabled: true,
                    title: title,
                    subtitle: subtitle,
                    submit_button_text: submit_button_text,
                    locale: active_locale,
                    fields: fields_data
                  }
                )
              end
            end
          end
        end
      end
    end
  end
end
