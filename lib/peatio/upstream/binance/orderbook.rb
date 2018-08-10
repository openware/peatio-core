class Peatio::Upstream::Binance::Orderbook
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
