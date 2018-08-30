# frozen_string_literal: true

require "faye/websocket"
require "em-http-request"
require "json"
require "openssl"
require "rbtree"
require "pp"

# Module provides access to trading on Binance upstream with following
# features:
#
# * Client for creating, cancelling orders;
# * Orderbook which is remote copy of Binance orderbook;
# * Trade monitoring;
module Peatio::Upstream::Binance
  require_relative "binance/orderbook"
  require_relative "binance/client"
  require_relative "binance/trader"

  def self.logger
    logger = Peatio::Logger.logger
    logger.progname = "binance"
    return logger
  end

  def self.run!(markets:)
    orderbooks = {}

    markets.each do |symbol|
      orderbooks[symbol] = Orderbook.new
    end

    streams = markets.product(["depth"])
      .map { |e| e.join("@") }.join("/")

    @@client = Client.new
    trader = Trader.new(@@client)

    @@client.connect_public_streams!(streams)

    @@client.public_stream.on :open do |event|
      logger.info "public streams connected: " + streams

      total = markets.length
      markets.each do |symbol|
        load_orderbook(symbol, orderbooks[symbol]) {
          total -= 1
          if total == 0
            yield if block_given?
          end
        }
      end
    end

    @@client.public_stream.on :message do |message|
      payload = JSON.parse(message.data)

      data = payload["data"]
      symbol, stream = payload["stream"].split("@")

      case stream
      when "depth"
        process_depth_diff(data, symbol, orderbooks)
      when "trade"
        process_trades(data, symbol, trader)
      end
    end

    @@client.public_stream.on :error do |message|
      logger.error(message)
    end

    return orderbooks, trader
  end

  def self.stop!
    @@client.public_stream.close
  end

  private

  def self.process_depth_diff(data, symbol, orderbooks)
    orderbook = orderbooks[symbol]
    generation = data["u"]

    asks, bids = update_orderbook(
      orderbook,
      data["a"],
      data["b"],
      generation
    )

    logger.debug "[#{symbol}] ##{generation} orderbook event: " \
      "%+d asks (%f min), %+d bids (%f max)" % [
        asks,
        orderbook.min_ask,
        bids,
        orderbook.max_bid,
      ]
  end

  def self.load_orderbook(symbol, orderbook)
    request = @@client.depth_snapshot(symbol)

    request.errback {
      logger.fatal "unable to request market depth for %s" % symbol

      raise
    }

    request.callback {
      if request.response_header.status != 200
        logger.fatal(
          "unexpected HTTP status code from binance: " \
          "#{request.response_header.status} #{request.response}"
        )

        raise
      end

      payload = JSON.parse(request.response)

      generation = payload["lastUpdateId"]
      bids = payload["bids"]
      asks = payload["asks"]

      logger.info "[#{symbol}] ##{generation} orderbook snapshot loaded: " \
                  "(#{bids.length} bids, #{asks.length} asks)"

      orderbook.commit(generation) {
        payload["bids"].each do |(price, volume)|
          orderbook.bid(price, volume, generation)
        end

        payload["asks"].each do |(price, volume)|
          orderbook.ask(price, volume, generation)
        end
      }

      yield if block_given?
    }
  end

  def self.update_orderbook(orderbook, asks, bids, generation)
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
end
