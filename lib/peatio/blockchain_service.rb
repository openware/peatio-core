module Peatio::BlockchainService

  class << self
    # TODO: Improve adapter methods.
    def register_adapter(name, klass)
      adapters[name] = klass
    end

    def get_adapter(name)
      adapters[name]
    end

    def adapters
      @adapters ||= {}
    end
  end
end
