module Peatio::MQ::Events
  def self.subscribe!
    Peatio::Logger.info "Starting to listen the queues..."
    Public.subscribe!
  end

  class SocketHandler
    @@all = []

    class << self
      def all
        @@all
      end
    end

    def initialize(socket, id)
      @socket = socket
      @id = id
      @@all << self
    end

    def send_payload(message)
      @socket.send message
    end
  end

  class Base < EM::Connection
    class << self
      def events_type(type)
        @events_type = ["peatio.events", type].join(".")
        @exchange = Peatio::MQ::Client.channel.direct(@events_type)
      end

      def watch(route, &block)
        bind_queue_for(route).subscribe do |metadata, payload|
          Peatio::Logger.debug "#{payload}"
          block.call(payload, metadata)
        end
      end

    protected

      def bind_queue_for(route)
        Peatio::MQ::Client.channel.queue(name_for(route)).bind(@exchange, routing_key: route)
      end

      def name_for(route)
        [@events_type, route].join(".")
      end
    end
  end

  class Public < Base
    def self.subscribe!
      events_type "market"

      watch("eurusd.order_created") do |payload, metadata|
        Peatio::Logger.debug "received order_created event"
        SocketHandler.all.each do |s|
          s.send_payload payload
        end
      end

      watch("eurusd.order_canceled") do |payload, metadata|
        Peatio::Logger.debug "received order_canceled event"
        SocketHandler.all.each do |s|
          s.send_payload payload
        end
      end

      watch("eurusd.trade_completed") do |payload, metadata|
        Peatio::Logger.debug "received trade_completed event"
        SocketHandler.all.each do |s|
          s.send_payload payload
        end
      end
    end
  end

end
