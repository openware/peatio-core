# frozen_string_literal: true

require "faye/websocket"
require "em-http-request"
require "json"
require "openssl"
require "rbtree"
require "pp"

module Peatio::Upstream::Binance
  class Orderbook
    class Entry
      attr_accessor :volume, :generation

      def initialize(volume, generation)
        @volume = volume
        @generation = generation
      end
    end

    def initialize
      @bids = RBTree.new
      @asks = RBTree.new
      @checkpoint = 0
    end

    def bid(price, volume, generation)
      return 0 if @checkpoint >= generation

      @bids[price] = Entry.new(volume, generation)
      if volume.to_f == 0
        @bids.delete(price)
        return -1
      else
        return 1
      end
    end

    def ask(price, volume, generation)
      return 0 if @checkpoint >= generation

      @asks[price] = Entry.new(volume, generation)
      if volume.to_f == 0
        @asks.delete(price)
        return -1
      else
        return 1
      end
    end

    def commit(generation)
      @asks.reject! { |_, entry| entry.generation <= generation }
      @bids.reject! { |_, entry| entry.generation <= generation }
      yield
      @checkpoint = generation
    end

    def min_ask
      return 0 if @asks.first.nil?

      @asks.first[0].to_f
    end

    def max_bid
      return 0 if @bids.last.nil?

      @bids.last[0].to_f
    end

    def match_bid(price)
      return price >= min_ask
    end

    def match_ask(price)
      return price <= max_bid
    end

    def depth(max_depth)
      asks = []
      bids = []

      @asks.each { |price, entry|
        asks << [price, entry.volume]
        break if asks.length >= max_depth
      }

      @bids.reverse_each { |price, entry|
        bids << [price, entry.volume]
        break if bids.length >= max_depth
      }

      return asks.reverse, bids
    end
  end

  class Client
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

  module_function

  def logger
    logger = Peatio::Logger.logger
    logger.progname = "binance"
    return logger
  end

  def load_orderbook(client, symbol, orderbook)
    request = client.depth_snapshot(symbol)

    request.errback {
      logger.fatal "unable to request market depth for %s" % symbol
      EM.stop
    }

    request.callback {
      if request.response_header.status != 200
        logger.fatal(
          "unexpected HTTP status code from binance: " \
          "#{request.response_header.status} #{request.response}"
        )
      end

      payload = JSON.parse(request.response)

      generation = payload["lastUpdateId"]
      bids = payload["bids"]
      asks = payload["asks"]

      logger.info "[#{symbol}] orderbook snapshot loaded: " \
                  "(#{bids.length} bids, #{asks.length} asks), " \
                  "id #{generation}"

      orderbook.commit(generation) {
        payload["bids"].each do |(price, volume)|
          orderbook.bid(price, volume, generation)
        end

        payload["asks"].each do |(price, volume)|
          orderbook.ask(price, volume, generation)
        end
      }
    }
  end

  def update_orderbook(orderbook, asks, bids, generation)
    asks_diff = 0
    asks.each do |(price, volume)|
      asks_diff += orderbook.ask(price, volume, generation)
    end

    bids_diff = 0
    bids.each do |(price, volume)|
      bids_diff += orderbook.bid(price, volume, generation)
    end

    return asks_diff, bids_diff
  end

  def run!(markets:)
    orderbooks = {}

    markets.each do |symbol|
      orderbooks[symbol] = Orderbook.new
    end

    streams = markets.map { |market| market + "@depth" }.join("/")

    client = Client.new
    client.stream_connect! streams

    client.stream.on :open do |event|
      logger.info "streams connected: " + streams

      markets.each do |symbol|
        load_orderbook(client, symbol, orderbooks[symbol])
      end
    end

    client.stream.on :message do |message|
      payload = JSON.parse(message.data)

      symbol, stream = payload["stream"].split("@")
      data = payload["data"]
      generation = data["u"]

      next if stream != "depth"

      orderbook = orderbooks[symbol]
      asks, bids = update_orderbook(
        orderbook,
        data["a"],
        data["b"],
        generation
      )

      logger.debug "[#{symbol}] orderbook event " \
        "id #{generation} processed: " \
        "%+d asks (%f min), %+d bids (%f max)" % [
          asks,
          orderbook.min_ask,
          bids,
          orderbook.max_bid,
        ]
    end

    client.stream.on :error do |message|
      logger.error(message)
    end

    return orderbooks
  end
end
