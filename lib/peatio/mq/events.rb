module Peatio::MQ::Events
  def self.subscribe!
    ranger = RangerEvents.new
    ranger.subscribe
  end

  def self.publish(event, payload)
    @@client ||= begin
      ranger = RangerEvents.new
      ranger.connect
      ranger
    end

    @@client.publish(event, payload) do
      yield if block_given?
    end
  end

  class SocketHandler
    attr_accessor :streams, :authorized, :user

    @@all = []

    def self.all
      @@all
    end

    def initialize(socket, streams)
      @socket = socket
      @streams = streams

      @user = ""
      @authorized = false

      @socket.onmessage { |msg|
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

    def publish(event, payload)
      serialized_data = JSON.dump(payload)

      @exchange.publish(serialized_data, routing_key: event) do
        Peatio::Logger::debug { "published event to #{event} " }

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

        stream = metadata.routing_key

        SocketHandler.all.each do |handler|
          if !handler.authorized
            next
          end

          if handler.streams.include?(stream)
            handler.send_payload payload
          end
        end
      end
    end
  end
end
