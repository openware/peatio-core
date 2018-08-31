# frozen_string_literal: true

# Class provides simple Binance client for working with both REST and WSS
# protocols.
#
# Class needs following environment variables to work:
#
# * +UPSTREAM_BINANCE_API_KEY+
# * +UPSTREAM_BINANCE_API_SECRET+
#
# Client intended for internal use and should not be used for working with
# Binance directly.
class Peatio::Upstream::Binance::Client
  @@uri_rest = "https://www.binance.com"
  @@uri_ws = "wss://stream.binance.com:9443"
  @@keepalive_interval = 600

  attr_accessor :config

  def initialize
    @config = {
      api_key: ENV["UPSTREAM_BINANCE_API_KEY"] || "",
      secret_key: ENV["UPSTREAM_BINANCE_API_SECRET"] || "",
      uri_rest: ENV["UPSTREAM_BINANCE_URI_REST"] || @@uri_rest,
      uri_ws: ENV["UPSTREAM_BINANCE_URI_WS"] || @@uri_ws,
    }

    raise "Upstream Binance API Key is not specified" if @config[:api_key] == ""
    raise "Upstream Binance Secret Key is not specified" if @config[:secret_key] == ""
  end

  # @return [Faye::Websocket::Client] Websocket connection to public streams.
  def connect_public_stream!(streams)
    ::Faye::WebSocket::Client.new(
      @config[:uri_ws] + "/stream?streams=" + streams
    )
  end

  # @yield [Faye::Websocket::Client] Yields block when listen key obtained and
  #   websocket stream connected.
  def connect_private_stream!()
    request = EM::HttpRequest.new(@config[:uri_rest] + "/api/v1/userDataStream").
      post(head: header)

    request.callback {
      payload = JSON.parse(request.response)
      key = payload["listenKey"]

      stream = ::Faye::WebSocket::Client.new(
        @config[:uri_ws] + "/ws/" + key,
      )

      EM::PeriodicTimer.new(@@keepalive_interval) {
        EM::HttpRequest.new(
          @config[:uri_rest] + "/api/v1/userDataStream?listenKey=" + key
        ).put(head: header)
      }

      yield(stream) if block_given?
    }
  end

  # @return [EM::HttpRequest] In-flight request for retrieving depth snapshot.
  def depth_snapshot(symbol, limit = 1000)
    EM::HttpRequest.new(@config[:uri_rest] + "/api/v1/depth").
      get(query: {'symbol': symbol.upcase, 'limit': limit})
  end

  # @param time_in_force [String] GTC = Goot till cancel, IOC = Immediate or Cancel
  # @return [EM::HttpRequest] In-flight request for submitting order.
  def submit_order(symbol:, side:, type:, quantity:, price: nil,
                   time_in_force: "GTC")
    raise "Invalid order: unexpected order side: #{side}" unless ["BUY", "SELL"].include?(side)
    raise "Invalid order: unexpected order type: #{type}" unless ["LIMIT", "MARKET"].include?(type)
    raise "Invalid order: price is not specified for LIMIT order" if price.nil? and type == "LIMIT"

    query = []
    query << ["symbol", symbol]
    query << ["side", side]
    query << ["type", type]
    query << ["quantity", quantity]
    query << ["newOrderRespType", "FULL"]

    if type == "LIMIT"
      query << ["timeInForce", time_in_force]
    end

    if !price.nil?
      query << ["price", price]
    end

    uri = sign!(query)

    EM::HttpRequest.new(
      @config[:uri_rest] + "/api/v3/order?" + uri
    ).post(head: header)
  end

  # @return [EM::HttpRequest] In-flight request for canceling order.
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
