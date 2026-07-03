# frozen_string_literal: true

module V1
  module Resources
    class Customers < Grape::API
      resource :customers do
        before do
          authenticate_user!
          check_api_feature!
          check_subscription!
        end

        desc 'Get a list of customers for the current account'
        params do
          optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
          optional :per_page, type: Integer, default: 20, values: 1..100
        end
        get do
          authorize!(:read, Customer)
          customers = current_account.customers.order(created_at: :desc)
          paginated = customers.page(params[:page]).per(params[:per_page])

          success(
            data: V1::Entities::CustomerEntity.render_as_hash(paginated),
            meta: {
              current_page: paginated.current_page,
              total_pages: paginated.total_pages,
              total_count: paginated.total_count
            }
          )
        end

        desc 'Get a single customer'
        params do
          requires :id, type: String, desc: 'Customer ID', allow_blank: false
        end
        get ':id' do
          authorize!(:read, Customer)
          customer = current_account.customers.find(params[:id])
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
          customer = current_account.customers.create!(
            name: params[:name],
            email: params[:email],
            phone_number: params[:phone_number]
          )

          success(data: V1::Entities::CustomerEntity.render_as_hash(customer))
        end
      end
    end
  end
end
