# frozen_string_literal: true

module V1
  module Entities
    class LabelEntity < Blueprinter::Base
      identifier :id

      fields :title, :identifier, :color, :description, :created_at
    end
  end
end
