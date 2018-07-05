module Peatio::Service
  module Registry
    class InvalidServiceError < StandardError; end
    class ServiceNotFoundError < StandardError; end

    class <<self
      def services
        @services ||= {}
      end

      def add!(service)
        return unless valid?(service)
        register(service)
      end

      def [](name)
        services.fetch(name) { raise ServiceNotFoundError }
      end

    private

      def register(service)
        services[service.name] = service
      end

      def valid?(service)
        return true if service.name && service.respond_to?(:run!)
        raise InvalidServiceError
      end
    end
  end
end
