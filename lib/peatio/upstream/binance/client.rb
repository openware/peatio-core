# frozen_string_literal: true

class Peatio::Upstream::Binance::Client
  @@uri_rest = "https://www.binance.com"
  @@uri_ws = "wss://stream.binance.com:9443"
  @@keepalive_interval = 600

  attr_accessor :config, :private_stream, :public_stream

  def initialize
    @config = {
      api_key: ENV["UPSTREAM_BINANCE_API_KEY"] || "",
      secret_key: ENV["UPSTREAM_BINANCE_SECRET_KEY"] || "",
      uri_rest: ENV["UPSTREAM_BINANCE_URI_REST"] || @@uri_rest,
      uri_ws: ENV["UPSTREAM_BINANCE_URI_WS"] || @@uri_ws,
    }

    raise "Upstream Binance API Key is not specified" if @config[:api_key] == ""
    raise "Upstream Binance Secret Key is not specified" if @config[:secret_key] == ""
  end

  def connect_public_streams!(streams)
    @public_stream = ::Faye::WebSocket::Client.new(
      @config[:uri_ws] + "/stream?streams=" + streams
    )
  end

  def connect_private_streams!()
    request = EM::HttpRequest.new(@config[:uri_rest] + "/api/v1/userDataStream").
      post(head: header)

    request.callback {
      payload = JSON.parse(request.response)
      key = payload["listenKey"]

      @private_stream = ::Faye::WebSocket::Client.new(
        @config[:uri_ws] + "/ws/" + key,
      )

      EM::PeriodicTimer.new(@@keepalive_interval) {
        EM::HttpRequest.new(
          @config[:uri_rest] + "/api/v1/userDataStream?listenKey=" + key
        ).put(head: header)
      }

      yield if block_given?
    }
  end

  def depth_snapshot(symbol, limit = 1000)
    EM::HttpRequest.new(@config[:uri_rest] + "/api/v1/depth").
      get(query: {'symbol': symbol.upcase, 'limit': limit})
  end

  def submit_order(symbol:, side:, type:, quantity:, price: nil,
                   time_in_force: "GTC")
    raise "Invalid order: unexpected order side: #{side}" unless ["BUY", "SELL"].include?(side)
    raise "Invalid order: unexpected order type: #{type}" unless ["LIMIT", "MARKET"].include?(type)
    raise "Invalid order: price is not specified for LIMIT order" if price.nil? and type == "LIMIT"

    query = []
    query << ["symbol", symbol]
    query << ["side", side]
    query << ["type", type]
    query << ["timeInForce", time_in_force]
    query << ["quantity", quantity]
    query << ["newOrderRespType", "FULL"]

    if !price.nil?
      query << ["price", price]
    end

    uri = sign!(query)

    EM::HttpRequest.new(
      @config[:uri_rest] + "/api/v3/order?" + uri
    ).post(head: header)
  end

  def cancel_order(symbol:, id:)
    query = []
    query << ["symbol", symbol]
    query << ["orderId", id]

    uri = sign!(query)

    EM::HttpRequest.new(
      @config[:uri_rest] + "/api/v3/order?" + uri
    ).delete(head: header)
  end

  private

  def sign!(query)
    query << ["timestamp", Time.now.to_i * 1000]

    signature = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha256"),
      @config[:secret_key],
      URI.encode_www_form(query)
    )

    query << ["signature", signature]

    URI::encode_www_form(query)
  end

  def header()
    {'X-MBX-APIKEY': @config[:api_key]}
  end
end
