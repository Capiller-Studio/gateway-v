# frozen_string_literal: true

module V1
  module Entities
    class MacroEntity < Blueprinter::Base
      identifier :id

      fields :name, :description, :visibility, :status, :actions, :system_provided, :created_at, :updated_at

      field :action_names do |macro|
        macro.action_names
      end

      field :scopeable_id do |macro|
        macro.scopeable_id
      end

      field :scopeable_type do |macro|
        macro.scopeable_type
      end
    end
  end
end
