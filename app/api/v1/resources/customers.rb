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

        desc 'Get a list of customers for the current account'
        params do
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 20, values: 1..100
        end
        get do
          authorize!(:read, Customer)
          records, meta = current_account.with_shard do
            customers = current_account.customers.order(created_at: :desc)
            paginate(customers)
          end

          success(
            data: V1::Entities::CustomerEntity.render_as_hash(records),
            meta: meta
          )
        end

        desc 'Get a single customer'
        params do
          requires :id, type: String, desc: 'Customer ID', allow_blank: false
        end
        get ':id' do
          authorize!(:read, Customer)
          customer = current_account.with_shard { current_account.customers.find(params[:id]) }
          success(data: V1::Entities::CustomerEntity.render_as_hash(customer))
        end

        desc 'Create a new customer'
        params do
          requires :name, type: String, allow_blank: false, desc: 'Customer Name'
          optional :email, type: String, regexp: URI::MailTo::EMAIL_REGEXP, desc: 'Customer Email'
          optional :phone_number, type: String, desc: 'Customer Phone Number'
        end
        post do
          authorize!(:write, Customer)
          customer = current_account.with_shard do
            c = current_account.customers.new(
              name: params[:name],
              email: params[:email],
              full_phone_number: params[:phone_number]
            )
            c.build_address unless c.address
            c.save!
            c
          end

          success(data: V1::Entities::CustomerEntity.render_as_hash(customer))
        end

        desc 'Update an existing customer'
        params do
          requires :id, type: String, desc: 'Customer ID', allow_blank: false
          optional :name, type: String, allow_blank: false
          optional :first_name, type: String
          optional :last_name, type: String
          optional :email, type: String, regexp: URI::MailTo::EMAIL_REGEXP
          optional :phone_number, type: String
          optional :custom_attributes, type: Hash
        end
        patch ':id' do
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
      end
    end
  end
end


