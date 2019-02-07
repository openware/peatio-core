module Peatio::BlockchainService
  ADAPTERS = {}

  class << self
    def register_adapter(name, klass)
      ADAPTERS[name] = klass
    end

    def get_adapter(name)
      ADAPTERS[name]
    end
  end
end
