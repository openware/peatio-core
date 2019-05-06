module Peatio
  class AdapterRegistry
    Error = Class.new(StandardError)
    DuplicatedAdapterError = Class.new(Error)
    NotRegisteredAdapterError = Class.new(Error)

    class << self
      def []=(name, instance)
        name = name.to_sym
        raise DuplicatedAdapterError, name if adapters.key?(name)
        adapters[name] = instance
      end

      def [](name)
        adapters.fetch(name.to_sym) { raise NotRegisteredAdapterError, name }
      end

      def adapters
        @adapters ||= {}
      end

      def adapters=(h)
        @adapters = h
      end
    end
  end
end
