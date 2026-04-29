# frozen_string_literal: true

module V1
  module Entities
    class AffiliateProfileEntity < Blueprinter::Base
      identifier :id
      fields :referral_code, :commission_rate, :currency, :created_at
    end
  end
end
