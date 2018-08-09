module Peatio::Ranger
  def run!
    logger = Peatio::Logger.logger
    port = 8081
    logger.info "Starting the server on port #{port}"

    EM.run do
      Peatio::MQ::Client.new
      Peatio::MQ::Events.subscribe!

      EM::WebSocket.start(host: "0.0.0.0", port: port) do |ws|
        ws.onopen do |id|
          logger.info "ranger: WebSocket connection openned"

          ws.instance_variable_set(
            :@connection_handler,
            Peatio::MQ::Events::SocketHandler.new(ws, "eurusd.order_created")
          )
        end

        ws.onclose { logger.info "ranger: WebSocket connection closed" }

        ws.onerror { |e|
          puts "ranger: WebSocket Error: #{e.message}"
        }
      end
    end
  end

  module_function :run!
end
