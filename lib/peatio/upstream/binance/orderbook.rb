# frozen_string_literal: true

# Class represents simplified version of remote orderbook.
#
# This object will be synchronized with remote orderbook asynchronously.
#
# It is not guaranteed that orderbook is 100% copy of remote orderbook at any
# given time.
#
# @see Binance
class Peatio::Upstream::Binance::Orderbook
  # @return [Float] Min ASK price.
  def min_ask
    return 0 if @asks.first.nil?

    @asks.first[0].to_f
  end

  # @return [Float] Max BID price.
  def max_bid
    return 0 if @bids.last.nil?

    @bids.last[0].to_f
  end

  # @return [Boolean] Returns true if BID with given price can be satisfied.
  def match_bid(price)
    return price >= min_ask
  end

  # @return [Boolean] Returns true if ASK with given price can be satisfied.
  def match_ask(price)
    return price <= max_bid
  end

  # @return [(Array<(Float, Float)>, Array<(Float, Float)>)] Returns ASK and BID
  #   arrays, where each element is pair of +Price+ and +Volume+.
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

  # @!visibility protected
  class Entry
    attr_accessor :volume, :generation

    def initialize(volume, generation)
      @volume = volume
      @generation = generation
    end
  end

  # @!visibility protected
  def initialize
    @bids = RBTree.new
    @asks = RBTree.new
    @checkpoint = 0
  end

  # @!visibility protected
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

  # @!visibility protected
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

  # @!visibility protected
  def commit(generation)
    @asks.reject! { |_, entry| entry.generation <= generation }
    @bids.reject! { |_, entry| entry.generation <= generation }
    yield
    @checkpoint = generation
  end
end
