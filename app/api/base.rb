# frozen_string_literal: true

class Base < Grape::API
  mount V1::Root
end
