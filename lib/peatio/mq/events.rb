module Peatio::MQ::Events
  def self.subscribe!
    RangerEvents.new
  end

  class SocketHandler
    @@all = []

    class << self
      def all
        @@all
      end
    end

    def initialize(socket)
      @socket = socket
      @@all << self
    end

    def send_payload(message)
      @socket.send message
    end
  end

  class RangerEvents
    def initialize
      require "socket"

      name = "peatio.events.market"
      suffix = "#{Socket.gethostname.split(/-/).last}#{Random.rand(10_000)}"
      exchange = Peatio::MQ::Client.channel.topic(name)
      Peatio::MQ::Client.channel
        .queue("#{name}.ranger.#{suffix}", durable: false, auto_delete: true)
        .bind(exchange, routing_key: "#").subscribe do |metadata, payload|

        Peatio::Logger.debug { "event received: #{payload}" }

        SocketHandler.all.each do |s|
          s.send_payload payload
        end
      end
    end
  end

end
