# frozen_string_literal: true

module V1
  module Resources
    module Sdk
      class Session < Grape::API
        resource :session do
          desc 'Initialize or resume customer SDK session'
          params do
            optional :jwt, type: String, desc: 'Client backend signed JWT'
            optional :identifier, type: String, desc: 'Customer unique identifier (external_id)'
            optional :signature, type: String, desc: 'HMAC-SHA256 signature of identifier'
            optional :email, type: String, desc: 'Customer email'
            optional :name, type: String, desc: 'Customer full name'
            optional :phone_number, type: String, desc: 'Customer phone number'
            optional :avatar_url, type: String, desc: 'Customer avatar image URL'
            optional :custom_attributes, type: Hash, default: {}, desc: 'Custom attributes metadata'
            optional :previous_session_token, type: String, desc: 'Previous anonymous session token to stitch conversations'
          end
          post do
            authenticate_sdk_channel!

            channel = current_channel
            inbox = current_inbox
            account = current_account

            verified_attrs = ::Channels::MobileWidgets::IdentityVerifier.call(channel: channel, params: params)

            if verified_attrs.nil?
              failure(errors: [{ code: "identity_verification_failed", message: "Identity verification failed or signature is invalid" }], status: 401)
            end

            external_id = verified_attrs[:external_id].presence || verified_attrs[:email].presence

            if external_id.blank?
              unless channel.anonymous_allowed?
                failure(errors: [{ code: "anonymous_disabled", message: "Anonymous chat is disabled. Please provide identity credentials." }], status: 401)
              end
              external_id = "anon-#{SecureRandom.uuid}"
            end

            customer = with_sdk_shard do
              cust = ::Customers::CustomerCreator.call(
                account: account,
                inbox: inbox,
                external_id: external_id,
                email: verified_attrs[:email],
                params: {
                  name: verified_attrs[:name],
                  full_phone_number: verified_attrs[:phone_number],
                  avatar_url: verified_attrs[:avatar_url],
                  locale: detect_locale,
                  data: verified_attrs[:custom_attributes] || {}
                }
              )

              if cust && verified_attrs[:email].present? && cust.email.blank?
                cust.update_column(:email, verified_attrs[:email].downcase)
              end
              cust
            end

            unless customer
              failure(errors: [{ code: "customer_creation_failed", message: "Unable to initialize customer profile" }], status: 422)
            end

            customer_inbox = with_sdk_shard do
              customer.customer_inboxes.find_by(inbox: inbox) ||
                ::Customers::CustomerInboxCreator.call(account: account, customer: customer, inbox: inbox, external_id: external_id)
            end

            # Stitch previous anonymous conversations if user was upgraded to authenticated
            if params[:previous_session_token].present?
              prev_payload = ::Channels::MobileWidgets::SessionToken.decode(params[:previous_session_token], channel: channel)
              if prev_payload && prev_payload[:customer_id].present? && prev_payload[:customer_id] != customer.id
                with_sdk_shard do
                  prev_customer = account.customers.find_by(id: prev_payload[:customer_id])
                  if prev_customer && prev_customer.external_id&.start_with?("anon-")
                    prev_customer.conversations.where(inbox: inbox).find_each do |conv|
                      cm = conv.conversation_members.find_by(member: prev_customer)
                      if cm
                        if conv.conversation_members.exists?(member: customer)
                          cm.destroy
                        else
                          cm.update(member: customer)
                        end
                      end
                      conv.messages.where(sender: prev_customer).update_all(sender_id: customer.id)
                    end
                  end
                end
              end
            end

            session_token = ::Channels::MobileWidgets::SessionToken.encode(
              customer: customer,
              customer_inbox: customer_inbox,
              channel: channel
            )

            cable_url = ENV.fetch("ACTION_CABLE_URL", "wss://ws-rely.capiller.com/cable")

            success(
              data: {
                session_token: session_token,
                connection_token: customer_inbox.connection_token,
                cable_url: cable_url,
                customer: V1::Entities::Sdk::CustomerEntity.render_as_hash(customer)
              }
            )
          end

          desc 'Update customer profile'
          params do
            optional :name, type: String
            optional :email, type: String
            optional :phone_number, type: String
            optional :avatar_url, type: String
          end
          patch :customer do
            authenticate_sdk_customer!

            updates = {}
            updates[:name] = params[:name] if params[:name].present?
            updates[:email] = params[:email].downcase.strip if params[:email].present?
            updates[:full_phone_number] = params[:phone_number] if params[:phone_number].present?

            with_sdk_shard do
              current_customer.update(updates) if updates.any?
            end

            success(data: V1::Entities::Sdk::CustomerEntity.render_as_hash(current_customer))
          end

          desc 'Logout customer and unregister session'
          params do
            optional :device_token, type: String, desc: 'Optional push token to unregister'
          end
          delete do
            authenticate_sdk_customer!

            with_sdk_shard do
              if params[:device_token].present?
                current_inbox.customer_devices.where(push_token: params[:device_token]).destroy_all
              end
              current_customer_inbox.regenerate_connection_token
            end

            success(message: 'Session closed successfully')
          end
        end
      end
    end
  end
end
