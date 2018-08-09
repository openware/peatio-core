module Peatio::MQ
  class Client
    class << self
      attr_reader :channel, :connection

      def new
        options = {
          host: ENV["RABBITMQ_HOST"] || "0.0.0.0",
          port: ENV["RABBITMQ_PORT"] || "5672",
          username: ENV["RABBITMQ_USER"],
          password: ENV["RABBITMQ_PASSWORD"],
        }
        @connection = AMQP.connect(options)
        @channel = AMQP::Channel.new(@connection)
      end

      def disconnect
        connection.close do
          yield
        end
      end
    end
  end
end
