module Peatio::Ranger
  class Connection
    def initialize(auth, socket, logger)
      @auth = auth
      @socket = socket
      @logger = logger
    end

    def onmessage(msg)
      begin
        data = JSON.parse(msg)

        token = data["jwt"]

        payload = auth.authenticate!
      rescue => error
        @logger.error error
        @socket.close
      end

      @client.user = payload[:uid]
      @client.authorized = true

      @logger.info "ranger: user #{client.user} authenticated #{streams}"
    end

    def onopen(handshake)
      query = URI::decode_www_form(handshake.query_string)

      streams = query.map do |item|
        if item.first == "stream"
          item.last
        end
      end

      @logger.info "ranger: WebSocket connection openned, streams: #{streams}"

      @client = Peatio::MQ::Events::Client.new(
        @socket, streams,
      )

      @socket.instance_variable_set(:@connection_handler, @client)
    end

    def onclose
      @logger.info "ranger: WebSocket connection closed"
    end

    def onerror(e)
      puts "ranger: WebSocket Error: #{e.message}"
    end
  end

  def self.run!(jwt_public_key)
    host = ENV["RANGER_HOST"] || "0.0.0.0"
    port = ENV["RANGER_PORT"] || "8081"

    auth = Peatio::Auth::JWTAuthenticator.new(jwt_public_key)

    logger = Peatio::Logger.logger
    logger.info "Starting the server on port #{port}"

    EM.run do
      Peatio::MQ::Client.new
      Peatio::MQ::Client.connect!
      Peatio::MQ::Client.create_channel!

      Peatio::MQ::Events.subscribe!

      EM::WebSocket.start(
        host: host,
        port: port,
        secure: true,
      ) do |socket|
        connection = Connection.new(auth, socket, logger)

        socket.onopen do |handshake|
          connection.onopen(handshake)
        end

        socket.onmessage do |msg|
          connection.onmessage(msg)
        end

        socket.onclose do
          connection.onclose
        end

        socket.onerror do |e|
          connection.onerror(e)
        end
      end

      yield if block_given?
    end
  end
end
