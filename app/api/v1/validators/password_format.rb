# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class PasswordFormatValidator < Base
        PASSWORD_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,128}\z/

        def validate_param!(attr_name, params)
          val = params[attr_name]
          return if val.blank?

          unless val.to_s.match?(PASSWORD_REGEX)
            fail Grape::Exceptions::Validation.new(
              params: [@scope.full_name(attr_name)],
              message: I18n.t(
                'gateway.errors.password_complexity',
                default: 'must be at least 8 characters long and include at least 1 uppercase letter, 1 lowercase letter, 1 number, and 1 special character'
              )
            )
          end
        end
      end
    end
  end
end
