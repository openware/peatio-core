require "peatio/service/registry"

module Peatio::Service
  module BaseService
    attr_reader :name

    # Register the service in the services registry
    def register(name, &block)
      @name = name
      @block = block

      Registry.add!(self)
    end

    # Run the service
    def run!
      @block.call
    end
  end
end
