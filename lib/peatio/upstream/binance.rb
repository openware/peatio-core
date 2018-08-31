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
# * Remote orderbooks objects that syncs in background and provides information
#   about current orderbook depth.
# * Trader that allows to execute given order with timeout and monitor its
#   state.
#
# All API provided by module is async.
class Peatio::Upstream::Binance
  include Peatio::Bus

  require_relative "binance/orderbook"
  require_relative "binance/client"
  require_relative "binance/trader"

  # @return [Client]
  attr_accessor :client

  # @return [Trader]
  attr_accessor :trader

  # Creates new upstream and initializes Binance API client.
  # Require configuration to work.
  #
  # Trader can be used immediately after object creation and can be accessed
  # as +binance.trader+.
  #
  # @see Client
  # @see Trader
  def initialize
    @client = Client.new
    @trader = Trader.new(@client)
  end

  # Connects to Binance and start to stream orderbook data.
  #
  # Method is non-blocking and orderbook data is available only after stream
  # is successfully connected.
  #
  # To subscribe on open event use +on(:open)+ callback to register block
  # that will receive +orderbooks+ object.
  #
  # Method should be invoked inside +EM.run{}+ loop
  #
  # @example
  #   EM.run {
  #     upstream = Peatio::Upstream::Binance.new
  #     binance.start(["tusdbtc"])
  #     binance.on(:open) { |orderbooks|
  #       tusdbtc = orderbooks["tusdbtc"]
  #       # ...
  #     }
  #
  #     binance.on(:error) { |message|
  #       puts(message)
  #     }
  #   }
  #
  # @param markets [Array<String>] List of markets to listen.
  # @see on
  # @return [self]
  def start!(markets)
    orderbooks = {}

    markets.each do |symbol|
      orderbooks[symbol] = Orderbook.new
    end

    streams = markets.product(["depth"])
      .map { |e| e.join("@") }.join("/")

    @stream = @client.connect_public_stream!(streams)

    @stream.on :open do |event|
      logger.info "public streams connected: " + streams

      total = markets.length
      markets.each do |symbol|
        load_orderbook(symbol, orderbooks[symbol]) {
          total -= 1
          if total == 0
            emit(:open, orderbooks)
          end
        }
      end
    end

    @stream.on :message do |message|
      payload = JSON.parse(message.data)

      data = payload["data"]
      symbol, stream = payload["stream"].split("@")

      case stream
      when "depth"
        process_depth_diff(data, symbol, orderbooks)
      end
    end

    @stream.on :error do |message|
      logger.error(message)
      emit(:error, message)
    end

    self
  end

  # Stop listening streams.
  #
  # After calling this method orderbooks will no longer be updated.
  def stop
    @stream.close
  end

  protected

  def self.logger
    logger = Peatio::Logger.logger
    logger.progname = "binance"
    return logger
  end

  def logger
    self.class.logger
  end

  private

  def process_depth_diff(data, symbol, orderbooks)
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

  def load_orderbook(symbol, orderbook)
    request = @client.depth_snapshot(symbol)

    request.errback {
      logger.fatal "unable to request market depth for %s" % symbol

      emit(:error)
    }

    request.callback {
      if request.response_header.status != 200
        logger.fatal(
          "unexpected HTTP status code from binance: " \
          "#{request.response_header.status} #{request.response}"
        )

        emit(:error)

        next
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
end
