# frozen_string_literal: true

module V1
  module Helpers
    module AuthorizationHelpers
      def authorize!(action, resource = nil)
        authenticate_user!

        permission = "#{derive_resource_name(resource)}.#{action}"

        unless current_account_user&.can?(permission, resource: resource)
          error!({
            success: false,
            errors: [{
              code: "forbidden",
              message: I18n.t("gateway.errors.forbidden", default: "You do not have permission to perform this action"),
              permission: permission
            }]
          }, 403)
        end
      end

      private

      def derive_resource_name(resource)
        case resource
        when Class
          resource.name.underscore.pluralize
        when nil
          'general'
        else
          resource.class.name.underscore.pluralize
        end
      end
    end
  end
end
