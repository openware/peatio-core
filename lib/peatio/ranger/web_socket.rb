# frozen_string_literal: true

module Peatio::Ranger
  def self.run(jwt_public_key, exchange_name, opts={})
    host = opts[:ranger_host] || ENV["RANGER_HOST"] || "0.0.0.0"
    port = opts[:ranger_port] || ENV["RANGER_PORT"] || "8081"

    authenticator = Peatio::Auth::JWTAuthenticator.new(jwt_public_key)

    logger = Peatio::Logger.logger
    logger.info "Starting the server on port #{port}"

    client = Peatio::MQ::Client.new
    router = Peatio::Ranger::Router.new
    client.subscribe(exchange_name, &router.method(:on_message))

    EM::WebSocket.start(
      host:   host,
      port:   port,
      secure: false
    ) do |socket|
      connection = Peatio::Ranger::Connection.new(router, socket, logger)
      socket.onopen do |hs|
        connection.handshake(authenticator, hs)
        router.on_connection_open(connection)
      end

      socket.onmessage do |msg|
        connection.handle(msg)
      end

      socket.onping do |value|
        logger.debug { "Received ping: #{value}" }
      end

      socket.onclose do
        logger.debug { "Websocket connection closed" }
        router.on_connection_close(connection)
      end

      socket.onerror do |e|
        logger.info { "WebSocket Error: #{e.message}" }
      end
    end
  end

  def self.run!(jwt_public_key, exchange_name, opts={})
    EM.run do
      run(jwt_public_key, exchange_name, opts)
    end
  end
end
