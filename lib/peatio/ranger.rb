module Peatio::Ranger
  class Connection
    def initialize(authenticator, socket, logger)
      @authenticator = authenticator
      @socket = socket
      @logger = logger
    end

    def send(method, data)
      payload = JSON.dump(method => data)
      @logger.debug { payload }
      @socket.send payload
    end

    def authenticate(jwt)
      payload = {}
      authorized = false
      begin
        payload = @authenticator.authenticate!(jwt)
        authorized = true
      rescue Peatio::Auth::Error => error
        @logger.error error.message
      end
      return [authorized, payload]
    end

    def update_streams
      @socket.instance_variable_set(:@connection_handler, @client)
    end

    def subscribe(streams)
      raise "Streams must be an array of strings" unless streams.is_a?(Array)
      streams.each do |stream|
        next if stream.nil?
        @client.streams[stream] = true
      end
      send :success, message: "subscribed", streams: @client.streams.keys
    end

    def unsubscribe(streams)
      raise "Streams must be an array of strings" unless streams.is_a?(Array)
      streams.each do |stream|
        next if stream.nil?
        @client.streams.delete(stream)
      end
      send :success, message: "unsubscribed", streams: @client.streams.keys
    end

    def handle(msg)
      begin
        data = JSON.parse(msg)

        if !data["jwt"].to_s.empty?
          authorized, payload = authenticate(data["jwt"])
          if !authorized
            send :error, message: "Authentication failed."
            return
          end
          @logger.info [authorized, payload].inspect
          @client.user = payload[:uid]
          @client.authorized = true
          @logger.info "ranger: user #{@client.user} authenticated #{@client.streams}"
          send :success, message: "Authenticated."
        end

        case data["event"]
        when "subscribe"
          subscribe data["streams"]
        when "unsubscribe"
          unsubscribe data["streams"]
        end

      rescue JSON::ParserError => error
        @logger.debug { "#{error}, msg: `#{msg}`" }
      end
    end

    def handshake(handshake)
      @client = Peatio::MQ::Events::Client.new(@socket)
      query = URI::decode_www_form(handshake.query_string)
      subscribe(query.map{ |item| item.last if item.first == "stream" })
      @logger.info "ranger: WebSocket connection openned"
    end
  end

  def self.run!(jwt_public_key)
    host = ENV["RANGER_HOST"] || "0.0.0.0"
    port = ENV["RANGER_PORT"] || "8081"

    authenticator = Peatio::Auth::JWTAuthenticator.new(jwt_public_key)

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
        secure: false,
      ) do |socket|
        connection = Connection.new(authenticator, socket, logger)

        socket.onopen do |handshake|
          connection.handshake(handshake)
        end

        socket.onmessage do |msg|
          connection.handle(msg)
        end

        socket.onclose do
          logger.info "ranger: WebSocket connection closed"
        end

        socket.onerror do |e|
          logger.error "ranger: WebSocket Error: #{e.message}"
        end
      end

      yield if block_given?
    end
  end
end
