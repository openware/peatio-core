module Peatio::Ranger
  def self.run!(jwt_public_key)
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
      ) { |socket|
        socket.onopen { |handshake|
          query = URI::decode_www_form(handshake.query_string)
          streams = query.map { |item|
            if item.first == "stream"
              item.last
            end
          }

          logger.info "ranger: WebSocket connection openned, streams: #{streams}"

          client = Peatio::MQ::Events::Client.new(
            socket, streams,
          )

          socket.onmessage { |msg|
            begin
              data = JSON.parse(msg)

              token = data["jwt"]

              auth = Peatio::Auth::JWTAuthenticator.new(token, jwt_public_key)
              payload = auth.authenticate!
            rescue => error
              Peatio::Logger::error error
              socket.close
            end

            client.user = payload[:uid]
            client.authorized = true

            logger.info "ranger: user #{client.user} authenticated #{streams}"
          }

          socket.instance_variable_set(:@connection_handler, client)
        }

        socket.onclose { logger.info "ranger: WebSocket connection closed" }

        socket.onerror { |e|
          puts "ranger: WebSocket Error: #{e.message}"
        }
      }
    end
  end
end
