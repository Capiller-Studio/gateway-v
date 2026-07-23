module Grape
  module Formatter
    module Oj
      def self.call(object, env)
        ::Oj.dump(object, mode: :compat)
      end
    end
  end
end
