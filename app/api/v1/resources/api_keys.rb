# frozen_string_literal: true

# NOTE: API Keys API is currently commented out as per design.
# module V1
#   module Resources
#     class ApiKeys < Grape::API
#       resource :api_keys do
#         before do
#           authenticate_user!
#           check_subscription!
#           check_api_feature!
#         end
#
#         desc 'Get all API keys for the current account'
#         params do
#           optional :page, type: Integer, default: 1, values: ->(v) { v.positive? }
#           optional :per_page, type: Integer, default: 50, values: 1..100
#         end
#         get do
#           authorize!(:manage, AccessToken)
#           tokens = AccessToken.where(owner: current_account, token_type: :api_key).order(created_at: :desc)
#           records, meta = paginate(tokens, per_page: params[:per_page] || 50)
#
#           success(
#             data: V1::Entities::ApiKeyEntity.render_as_hash(records),
#             meta: meta
#           )
#         end
#
#         desc 'Generate a new API key'
#         params do
#           optional :valid_till, type: DateTime, desc: 'Optional expiry date'
#         end
#         post do
#           authorize!(:manage, AccessToken)
#           token = AccessToken.create!(
#             owner: current_account,
#             token: SecureRandom.hex(24),
#             token_type: :api_key,
#             valid_till: params[:valid_till]
#           )
#
#           status 201
#           success(
#             data: V1::Entities::ApiKeyEntity.render_as_hash(token),
#             message: 'API key generated successfully'
#           )
#         end
#
#         route_param :id do
#           desc 'Revoke an API key'
#           delete do
#             authorize!(:manage, AccessToken)
#             token = AccessToken.where(owner: current_account, token_type: :api_key).find(params[:id])
#             token.destroy!
#
#             success(message: 'API key revoked successfully')
#           end
#         end
#       end
#     end
#   end
# end
