# frozen_string_literal: true

module Peatio::MQ
  class Client
    class << self
      attr_accessor :connection

      def connect!
        options = {
          host:     ENV["RABBITMQ_HOST"] || "0.0.0.0",
          port:     ENV["RABBITMQ_PORT"] || "5672",
          username: ENV["RABBITMQ_USER"],
          password: ENV["RABBITMQ_PASSWORD"],
        }
        @connection = Bunny.new(options)
        @connection.start
      end

      def disconnect
        @connection.close
      end
    end

    def initialize
      Client.connect! unless Peatio::MQ::Client.connection
      @channel = Client.connection.create_channel
      @exchanges = {}
    end

    def exchange(name, type="topic")
      @exchanges[name] ||= @channel.exchange(name, type: type)
    end

    def publish(ex_name, type, id, event, payload)
      routing_key = [type, id, event].join(".")
      serialized_data = JSON.dump(payload)
      exchange(ex_name).publish(serialized_data, routing_key: routing_key)
      Peatio::Logger.debug { "published event to #{routing_key} " }
    end

    def subscribe(ex_name, &callback)
      suffix = "#{Socket.gethostname.split(/-/).last}#{Random.rand(10_000)}"
      queue_name = "ranger.#{suffix}"

      @channel
        .queue(queue_name, durable: false, auto_delete: true)
        .bind(exchange(ex_name), routing_key: "#").subscribe(&callback)
      Peatio::Logger.info "Subscribed to exchange #{ex_name}"
    end
  end
end
