require "peatio/service/registry"

require "peatio/service/global_state"

module Peatio::Service
  class Root < Clamp::Command
    subcommand 'run', 'Run a service' do
      parameter "SERVICE ARGS...", "Service to run", attribute_name: :service

      def execute
        Registry[service].run!
      rescue Registry::ServiceNotFoundError
        signal_usage_error "Service `#{service}` is not found"
      end
    end

    subcommand ['ls', 'list'], 'List all available services' do
      def execute
        puts "Available services:"
        puts Registry.services.keys
      end
    end
  end
end
