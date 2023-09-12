# frozen_string_literal: true

module Peatio
  module Ramp
    class << self
      def registry
        @registry ||= Registry.new
      end

      class Registry < Peatio::AdapterRegistry
      end
    end
  end
end
