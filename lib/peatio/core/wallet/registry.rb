require "peatio/core/adapter_registry"

module Peatio
  module Core
    module Wallet

      VERSION = "1.0.0".freeze

      class << self
        def registry
          @registry ||= Registry.new
        end
      end
      class Registry < Peatio::Core::AdapterRegistry
      end
    end
  end
end
