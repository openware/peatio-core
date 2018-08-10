# frozen_string_literal: true

require "faye/websocket"
require "em-http-request"
require "json"
require "openssl"
require "rbtree"
require "pp"

module Peatio::Upstream::Binance
  require_relative "binance/orderbook"
  require_relative "binance/client"

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
