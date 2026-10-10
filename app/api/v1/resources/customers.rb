# frozen_string_literal: true

module V1
  module Resources
    class Customers < Grape::API
      resource :customers do
        before do
          authenticate_user!
          check_subscription!
          check_api_feature!
        end

        desc 'Get a list of customers for the current account with search and filters'
        params do
          optional :q, type: String, desc: 'Search query across name, email, and phone'
          optional :email, type: String, desc: 'Exact email search'
          optional :phone_number, type: String, desc: 'Exact phone search'
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 20, values: 1..100
        end
        get do
          authorize!(:read, Customer)
          records, meta = current_account.with_shard do
            scope = current_account.customers.order(created_at: :desc)

            if params[:q].present?
              search_term = "%#{params[:q].to_s.strip}%"
              scope = scope.where('name ILIKE :q OR email ILIKE :q OR full_phone_number ILIKE :q', q: search_term)
            end

            scope = scope.where(email: params[:email]) if params[:email].present?
            scope = scope.where(full_phone_number: params[:phone_number]) if params[:phone_number].present?

            paginate(scope, page: params[:page] || 1, per_page: params[:per_page] || 20)
          end

          success(
            data: V1::Entities::CustomerEntity.render_as_hash(records),
            meta: meta
          )
        end

        desc 'Create a new customer'
        params do
          requires :name, type: String, allow_blank: false, desc: 'Customer Name'
          optional :first_name, type: String
          optional :last_name, type: String
          optional :email, type: String, regexp: URI::MailTo::EMAIL_REGEXP, desc: 'Customer Email'
          optional :phone_number, type: String, desc: 'Customer Phone Number'
          optional :custom_attributes, type: Hash, desc: 'Custom attributes hash'
          optional :address, type: Hash do
            optional :address_line_1, type: String
            optional :address_line_2, type: String
            optional :city, type: String
            optional :state, type: String
            optional :country, type: String
            optional :zip_code, type: String
          end
        end
        post do
          authorize!(:write, Customer)
          customer = current_account.with_shard do
            c = current_account.customers.new(
              name: params[:name],
              first_name: params[:first_name],
              last_name: params[:last_name],
              email: params[:email],
              full_phone_number: params[:phone_number],
              data: params[:custom_attributes] || {}
            )

            if params[:address].present?
              c.build_address(
                address1: params[:address][:address1] || params[:address][:address_line_1],
                address2: params[:address][:address2] || params[:address][:address_line_2],
                city: params[:address][:city],
                state_name: params[:address][:state],
                zipcode: params[:address][:zipcode] || params[:address][:zip_code]
              )
            else
              c.build_address
            end

            c.save!
            c
          end

          success(data: V1::Entities::CustomerEntity.render_as_hash(customer))
        end

        route_param :id do
          desc 'Get a single customer'
          get do
            authorize!(:read, Customer)
            customer = current_account.with_shard { current_account.customers.find(params[:id]) }
            success(data: V1::Entities::CustomerEntity.render_as_hash(customer))
          end

          desc 'Update an existing customer'
          params do
            optional :name, type: String, allow_blank: false
            optional :first_name, type: String
            optional :last_name, type: String
            optional :email, type: String, regexp: URI::MailTo::EMAIL_REGEXP
            optional :phone_number, type: String
            optional :custom_attributes, type: Hash
          end
          patch do
            authorize!(:write, Customer)
            customer = current_account.with_shard do
              c = current_account.customers.find(params[:id])
              update_attrs = {}
              update_attrs[:name] = params[:name] if params[:name].present?
              update_attrs[:first_name] = params[:first_name] if params[:first_name].present?
              update_attrs[:last_name] = params[:last_name] if params[:last_name].present?
              update_attrs[:email] = params[:email] if params[:email].present?
              update_attrs[:full_phone_number] = params[:phone_number] if params[:phone_number].present?

              if params[:custom_attributes].present?
                c.data = (c.data || {}).merge(params[:custom_attributes])
              end

              c.update!(update_attrs)
              c
            end

            success(data: V1::Entities::CustomerEntity.render_as_hash(customer))
          end

          desc 'Delete a customer'
          delete do
            authorize!(:destroy, Customer)
            current_account.with_shard do
              c = current_account.customers.find(params[:id])
              c.destroy!
            end

            success(message: 'Customer deleted successfully')
          end

          desc 'Get customer conversation history'
          params do
            optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
            optional :per_page, type: Integer, default: 20, values: 1..50
          end
          get :conversations do
            authorize!(:read, Conversation)
            records, meta = current_account.with_shard do
              customer = current_account.customers.find(params[:id])
              convs = customer.conversations.includes(:inbox, :assignee, :team, :labels).order(created_at: :desc)
              paginate(convs, page: params[:page] || 1, per_page: params[:per_page] || 20)
            end

            success(
              data: V1::Entities::ConversationEntity.render_as_hash(records, current_user: current_user),
              meta: meta
            )
          end

          desc 'Get customer internal notes'
          get :notes do
            authorize!(:read, Customer)
            notes = current_account.with_shard do
              customer = current_account.customers.find(params[:id])
              customer.notes.includes(:user).order(created_at: :desc).map do |n|
                {
                  id: n.id,
                  content: n.content,
                  user_id: n.user_id,
                  user_name: n.user&.name || n.user&.display_name,
                  created_at: n.created_at
                }
              end
            end

            success(data: notes)
          end

          desc 'Add an internal note to customer'
          params do
            requires :content, type: String, allow_blank: false, desc: 'Note content'
          end
          post :notes do
            authorize!(:write, Customer)
            note = current_account.with_shard do
              customer = current_account.customers.find(params[:id])
              customer.notes.create!(
                account: current_account,
                user: current_user,
                content: params[:content],
                visibility: :personal
              )
            end

            success(
              data: {
                id: note.id,
                content: note.content,
                user_id: note.user_id,
                user_name: current_user.name,
                created_at: note.created_at
              }
            )
          end
        end
      end
    end
  end
end
