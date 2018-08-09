module Peatio::MQ::Events
  def self.subscribe!
    ranger = RangerEvents.new
    ranger.subscribe
  end

  def self.start!
  end

  class SocketHandler
    attr_accessor :event

    @@all = []

    class << self
      def all
        @@all
      end
    end

    def initialize(socket, event)
      @socket = socket
      @event = event
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

    def subscribe
      require "socket"

      exchange = Peatio::MQ::Client.channel.topic(@exchange_name)

      suffix = "#{Socket.gethostname.split(/-/).last}#{Random.rand(10_000)}"

      queue_name = "#{@topic_name}.ranger.#{suffix}"

      Peatio::MQ::Client.channel
        .queue(queue_name, durable: false, auto_delete: true)
        .bind(exchange, routing_key: "#").subscribe do |metadata, payload|

        Peatio::Logger.debug { "event received: #{payload}" }

        event = metadata.routing_key

        SocketHandler.all.each do |handler|
          if event == handler.event
            handler.send_payload payload
          end
        end
      end
    end
  end

end
