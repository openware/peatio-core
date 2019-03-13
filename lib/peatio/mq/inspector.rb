module Peatio::MQ
  class Inspector
    def run!
      @logger = Peatio::Logger.logger
      EventMachine.run do
        Peatio::MQ::Client.new
        Peatio::MQ::Client.connect!
        Peatio::MQ::Client.create_channel!
        subscribe("direct", "peatio.events.model")
        subscribe("direct", "peatio.events.market")
        subscribe("direct", "barong.events.model")
        subscribe("direct", "barong.events.system", ["user.email.confirmation.token", "user.password.reset.token"])
      end

    end

    def log_message(exchange_name, delivery_info, metadata, payload)
      routing_key = delivery_info.routing_key
      payload_decoded = JSON.parse(payload)
      data = JSON.parse(Base64.decode64(payload_decoded["payload"]))
      @logger.debug "Exchange: #{exchange_name}, routing: #{routing_key}, data: #{data}"
    end

    def subscribe(type, exchange_name, routing_keys = nil)
      suffix = "inspector-#{Socket.gethostname.split(/-/).last}-#{Random.rand(10_000)}"
      queue_name = "#{exchange_name}.#{suffix}"

      case type
      when "direct"
        exchange = Peatio::MQ::Client.channel.direct(exchange_name)
        queue = Peatio::MQ::Client.channel.queue(queue_name, durable: false, auto_delete: true)
        if routing_keys
          routing_keys.each do |routing_key|
            queue.bind(exchange, routing_key: routing_key).subscribe { |*args| log_message(exchange_name, *args) }
          end
        else
          queue.bind(exchange).subscribe { |*args| log_message(exchange_name, *args) }
        end
      else
        raise "Unhandled exchange type: #{type}"
      end
    end
  end
end
