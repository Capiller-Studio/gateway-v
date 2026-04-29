# frozen_string_literal: true

module V1
  module Helpers
    module ResponseHelpers
      # Standard success response
      #
      # Example:
      #   success(data: UserEntity.render_as_hash(user))
      #   => { "data" => { ... }, "meta" => {} }
      #
      #   success(data: users, meta: { pagination: { page: 1, total: 50 } })
      #   => { "data" => [ ... ], "meta" => { "pagination" => { ... } } }
      #
      def success(data:, meta: {})
        { data: data, meta: meta }
      end

      # Standard error response
      #
      # Example:
      #   failure(errors: [{ field: "email", message: "has already been taken" }], status: 422)
      #
      def failure(errors:, status: 400)
        error!({ errors: Array(errors) }, status)
      end
    end
  end
end
