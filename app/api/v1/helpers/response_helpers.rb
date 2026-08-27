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
      def success(data: nil, message: nil, meta: {})
        res = {}
        res[:message] = message if message.present?
        res[:data] = data unless data.nil?
        res[:meta] = meta
        res
      end

      # Standard error response
      #
      # Example:
      #   failure(errors: [{ field: "email", message: "has already been taken" }], status: 422)
      #
      def failure(errors:, status: 400)
        error!({ errors: Array(errors) }, status)
      end

      # Standard pagination helper for ActiveRecord relations
      #
      # Returns [paginated_records, meta_hash]
      #
      def paginate(relation, page: (params[:page] || 1).to_i, per_page: (params[:per_page] || 20).to_i)
        page = [page.to_i, 1].max
        per_page = [[per_page.to_i, 1].max, 100].min

        total_count = relation.count
        total_pages = total_count.zero? ? 1 : (total_count.to_f / per_page).ceil
        offset = (page - 1) * per_page

        records = relation.offset(offset).limit(per_page)

        meta = {
          current_page: page,
          total_pages: total_pages,
          total_count: total_count,
          per_page: per_page
        }

        [records, meta]
      end
    end
  end
end

