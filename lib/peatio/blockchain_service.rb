module Peatio
  module BlockchainService
    Error = Class.new(StandardError)
    DuplicatedAdapterError = Class.new(Error)
    NotRegisteredAdapterError = Class.new(Error)

    class << self
      def register_adapter(name, klass)
        raise DuplicatedAdapterError if adapters.key?(name)
        adapters[name.to_sym] = klass
      end

      def adapter_for(name)
        adapters.fetch(name) { raise NotRegisteredAdapterError }
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
