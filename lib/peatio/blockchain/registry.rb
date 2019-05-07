require 'peatio/adapter_registry'

module Peatio
  module Blockchain
    class << self
      def registry
        @registry ||= Registry.new
      end
    end
    class Registry < Peatio::AdapterRegistry
    end
  end
end
