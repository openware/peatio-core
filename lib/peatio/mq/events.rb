module Peatio::MQ::Events
  def self.subscribe!
    ranger = RangerEvents.new
    ranger.subscribe
  end

  def self.publish(type, id, event, payload)
    @@client ||= begin
      ranger = RangerEvents.new
      ranger.connect
      ranger
    end

    @@client.publish(type, id, event, payload) do
      yield if block_given?
    end
  end

  class SocketHandler
    attr_accessor :streams, :authorized, :user

    @@all = []

    def self.all
      @@all
    end

    def self.user(user)
      @@all.each do |handler|
        if handler.user == user
          yield handler
        end
      end
    end

    def initialize(socket, streams)
      @socket = socket
      @streams = streams

      @user = ""
      @authorized = false

      @socket.onmessage { |msg|
        msg.strip!

        @authorized = true
        @user = msg
      }

      @@all << self
    end

    def send_payload(message)
      @socket.send message
    end
  end

  class RangerEvents
    attr_accessor :exchange_name

    def initialize
      @exchange_name = "peatio.events.market"
    end

    def connect
      @exchange = Peatio::MQ::Client.channel.topic(@exchange_name)
    end

    def publish(type, id, event, payload)
      routing_key = [type, id, event].join(".")
      serialized_data = JSON.dump(payload)

      @exchange.publish(serialized_data, routing_key: routing_key) do
        Peatio::Logger::debug { "published event to #{routing_key} " }

        yield if block_given?
      end
    end

    def subscribe
      require "socket"

      exchange = Peatio::MQ::Client.channel.topic(@exchange_name)

      suffix = "#{Socket.gethostname.split(/-/).last}#{Random.rand(10_000)}"

      queue_name = "#{@topic_name}.ranger.#{suffix}"

      Peatio::MQ::Client.channel
        .queue(queue_name, durable: false, auto_delete: true)
        .bind(exchange, routing_key: "#").subscribe do |metadata, payload|

        #Peatio::Logger.debug { "event received: #{payload}" }

        # type@id@event
        # type can be public|private
        # id can be user id or market
        # event can be anything like order_completed or just trade

        routing_key = metadata.routing_key
        if routing_key.count(".") != 2
          Peatio::Logger::error {
            "got invalid routing key from amqp: #{routing_key}"
          }
          next
        end

        type, id, event = routing_key.split(".")

        if type == "private"
          SocketHandler.user(id) do |handler|
            if handler.streams.include?(event)
              handler.send_payload payload
            end
          end

          next
        end

        stream = [id, event].join(".")

        SocketHandler.all.each do |handler|
          if handler.streams.include?(stream)
            handler.send_payload payload
          end
        end
      end
    end
  end
end
