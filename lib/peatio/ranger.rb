module Peatio::Ranger
  def start_server!
    host = ENV["RANGER_HOST"] || "0.0.0.0"
    port = ENV["RANGER_PORT"] || "8081"

    logger = Peatio::Logger.logger
    logger.info "Starting the server on port #{port}"

    EM.run do
      Peatio::MQ::Client.new
      Peatio::MQ::Events.subscribe!

      EM::WebSocket.start(
        host: host,
        port: port,
        secure: true,
      ) do |ws|
        ws.onopen do |handshake|
          query = URI::decode_www_form(handshake)

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
