module Peatio::MQ
  class Client
    class << self
      attr_accessor :channel, :connection

      def new
        @options = {
          host: ENV["RABBITMQ_HOST"] || "0.0.0.0",
          port: ENV["RABBITMQ_PORT"] || "5672",
          username: ENV["RABBITMQ_USER"],
          password: ENV["RABBITMQ_PASSWORD"],
        }
      end

      def connect!
        @connection = Bunny.new(@options)
        @connection.start
      end

      def create_channel!
        @channel = @connection.create_channel
      end

      def disconnect
        @connection.close
        yield if block_given?
      end
    end
  end
end
