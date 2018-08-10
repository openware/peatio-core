class Peatio::Upstream::Binance::Client
  @@uri_rest = "https://www.binance.com"
  @@uri_ws = "wss://stream.binance.com:9443"

  attr_accessor :client, :config, :stream

  def initialize
    @config = {
      :api_key => ENV["UPSTREAM_BINANCE_API_KEY"] || "",
      :secret_key => ENV["UPSTREAM_BINANCE_SECRET_KEY"] || "",
      :uri_rest => ENV["UPSTREAM_BINANCE_URI_REST"] || @@uri_rest,
      :uri_ws => ENV["UPSTREAM_BINANCE_URI_WS"] || @@uri_ws,
    }

    raise "Upstream Binance API Key is not specified" if @config[:api_key] == ""
    raise "Upstream Binance Secret Key is not specified" if @config[:secret_key] == ""
  end

  def stream_connect!(streams)
    @stream = ::Faye::WebSocket::Client.new(
      @config[:uri_ws] + "/stream?streams=" + streams
    )
  end

  def depth_snapshot(symbol, limit = 1000)
    EM::HttpRequest.new(@config[:uri_rest] + "/api/v1/depth").
      get(query: {'symbol': symbol.upcase, 'limit': limit})
  end

  def self.sign!(data)
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha256"),
      @config[:secret_key],
      data
    )
  end

  def submit_order(symbol, side, type, quantity, price = nil)
    raise "Invalid order: unexpected order side: #{side}" unless ["BUY", "SELL"].include?(side)
    raise "Invalid order: unexpected order type: #{type}" unless ["LIMIT", "MARKET"].include?(type)
    raise "Invalid order: price is not specified for LIMIT order" if price.nil? and type == "LIMIT"

    query = []
    query << ["symbol", symbol]
    query << ["side", side]
    query << ["type", type]
    query << ["timeInForce", timeInForce]
    query << ["quantity", quantity]
    query << ["newOrderRespType", "FULL"]

    if !price.nil?
      query << ["price", price]
    end

    query << ["timestamp", Time.now.to_i]

    # we can specify our own unique order id
    #query << ["newClientOrderId", ""]

    signature = self.sign!(URI.encode_www_form(query))

    query << ["signature", signature]

    header = {'X-MBX-APIKEY': @config[:api_key]}
  end
end
