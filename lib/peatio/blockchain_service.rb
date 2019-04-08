module Peatio
  module BlockchainService
    Error = Class.new(StandardError)
    DuplicatedAdapterError = Class.new(Error)
    NotRegisteredAdapterError = Class.new(Error)

    class << self
      def register_adapter(name, klass)
        name = name.to_sym
        raise DuplicatedAdapterError if adapters.key?(name)
        adapters[name] = klass
      end

      def adapter_for(name)
        adapters.fetch(name.to_sym) { raise NotRegisteredAdapterError }
      end

      def adapters
        @adapters ||= {}
      end

      def adapters=(h)
        @adapters = h
      end
    end

    module Helpers
      def cache_key(*suffixes)
        [self.class.name.underscore.gsub("/", ":"), suffixes].join(":")
      end
    end
  end
end
