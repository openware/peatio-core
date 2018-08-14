module Peatio::Ranger
  def run!
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
      ) do |socket|
        socket.onopen do |handshake|
          query = URI::decode_www_form(handshake.query_string)
          streams = query.map { |item|
            if item.first == "stream"
              item.last
            end
          }

          logger.info "ranger: WebSocket connection openned, streams: #{streams}"

          socket.instance_variable_set(
            :@connection_handler,
            Peatio::MQ::Events::SocketHandler.new(
              socket,
              streams
            )
          )
        end

        socket.onclose { logger.info "ranger: WebSocket connection closed" }

        socket.onerror { |e|
          puts "ranger: WebSocket Error: #{e.message}"
        }
      end
    end
  end

  module_function :run!
end
