# frozen_string_literal: true

module V1
  module Helpers
    module ResponseHelpers
      # Standard success response
      #
      # Example:
      #   success(data: UserEntity.render_as_hash(user))
      #   => { "success" => true, "data" => { ... }, "meta" => {} }
      #
      #   success(data: users, meta: { pagination: { page: 1, total: 50 } })
      #   => { "success" => true, "data" => [ ... ], "meta" => { "pagination" => { ... } } }
      #
      def success(data: nil, message: nil, meta: {})
        res = { success: true }
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
      def failure(errors:, status: 400, message: nil)
        formatted_errors = if errors.is_a?(Array)
                             errors.map { |e| e.is_a?(Hash) ? e : { message: e.to_s } }
                           elsif errors.is_a?(Hash)
                             [errors]
                           else
                             [{ message: errors.to_s }]
                           end

        payload = { success: false, errors: formatted_errors }
        payload[:message] = message if message.present?
        error!(payload, status)
      end

      # Standard offset pagination helper for ActiveRecord relations
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

        pagination_info = {
          current_page: page,
          total_pages: total_pages,
          total_count: total_count,
          per_page: per_page
        }

        meta = {
          current_page: page,
          total_pages: total_pages,
          total_count: total_count,
          per_page: per_page,
          pagination: pagination_info
        }

        [records, meta]
      end

      # Standard cursor pagination helper for real-time streams (chat messages)
      #
      # Returns [records, meta_hash]
      #
      def paginate_cursor(relation, before_id: params[:before_id], after_id: params[:after_id], limit: (params[:limit] || 50).to_i, order_column: :created_at, id_column: :id)
        limit = [[limit.to_i, 1].max, 100].min

        if before_id.present?
          ref_record = relation.find_by(id_column => before_id)
          if ref_record
            ref_val = ref_record.send(order_column)
            relation = relation.where("#{order_column} < ? OR (#{order_column} = ? AND #{id_column} < ?)",
                                      ref_val, ref_val, ref_record.send(id_column))
          end
        elsif after_id.present?
          ref_record = relation.find_by(id_column => after_id)
          if ref_record
            ref_val = ref_record.send(order_column)
            relation = relation.where("#{order_column} > ? OR (#{order_column} = ? AND #{id_column} > ?)",
                                      ref_val, ref_val, ref_record.send(id_column))
          end
        end

        records = relation.limit(limit).to_a
        first_rec = records.first
        last_rec = records.last

        meta = {
          limit: limit,
          count: records.size,
          before_id: first_rec&.send(id_column)&.to_s,
          after_id: last_rec&.send(id_column)&.to_s,
          pagination: {
            limit: limit,
            count: records.size,
            before_id: first_rec&.send(id_column)&.to_s,
            after_id: last_rec&.send(id_column)&.to_s
          }
        }

        [records, meta]
      end
    end
  end
end

