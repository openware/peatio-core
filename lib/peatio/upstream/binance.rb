# frozen_string_literal: true

require "faye/websocket"
require "em-http-request"
require "json"

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
      @bids = {}
      @asks = {}
      @checkpoint = 0
    end

    def bid(price, volume, generation)
      return if @checkpoint >= generation

      @bids[price] = Entry.new(volume, generation)
      if volume.to_f == 0
        @bids.delete(price)
        return -1
      else
        return 1
      end
    end

    def ask(price, volume, generation)
      return if @checkpoint >= generation

      @asks[price] = Entry.new(volume, generation)
      if volume.to_f == 0
        @asks.delete(price)
        return -1
      else
        return 1
      end
    end

    def commit(generation)
      @asks.reject! { |entry| entry.generation <= generation }
      @bids.reject! { |entry| entry.generation <= generation }
      yield
      @checkpoint = generation
    end
  end

  class Client
    attr_accessor :client, :config, :stream

    def initialize
      @config = {
        api_key: ENV["UPSTREAM_BINANCE_API_KEY"],
        secret_key: ENV["UPSTREAM_BINANCE_SECRET_KEY"],
      }
    end

    def stream_connect!(streams)
      @stream = ::Faye::WebSocket::Client.new(
        "wss://stream.binance.com:9443/stream?streams=" + streams
      )
    end
  end

  module_function

  def logger
    logger = Peatio::Logger.logger
    logger.progname = "binance"
    return logger
  end

  def run!(markets:)
    orderbooks = {}

    markets.each do |symbol|
      orderbooks[symbol] = Orderbook.new
    end

    streams = markets.map { |market| market + "@depth" }.join("/")

    EM.run {
      client = Client.new
      client.stream_connect! streams
      client.stream.on :open do |event|
        logger.info "streams connected: " + streams
      end

      client.stream.on :error do |message|
        logger.error message
      end

      client.stream.on :message do |message|
        payload = JSON.parse(message.data)
        symbol, stream = payload["stream"].split("@")

        generation = payload["data"]["u"]

        bids = 0
        payload["data"]["b"].each do |(price, volume)|
          bids += orderbooks[symbol].bid(price, volume, generation)
        end

        asks = 0
        payload["data"]["a"].each do |(price, volume)|
          asks += orderbooks[symbol].ask(price, volume, generation)
        end

        logger.debug "[#{symbol}] orderbook event " \
          "id #{generation} processed: " \
          "%+d bids, %+d asks" % [
            bids,
            asks
          ]
      end

      markets.each do |symbol|
        request = EM::HttpRequest.new("https://www.binance.com/api/v1/depth").
          get(query: {'symbol': symbol.upcase, 'limit': 1000})

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
            "(#{bids.length} bids, #{asks.length} asks), "\
            "id #{generation}"

          orderbooks[symbol].commit(generation) {
            payload["bids"].each do |(price, volume)|
              orderbooks[symbol].bid(price, volume, generation)
            end

            payload["asks"].each do |(price, volume)|
              orderbooks[symbol].ask(price, volume, generation)
            end
          }
        }
      end
    }
  end
end
