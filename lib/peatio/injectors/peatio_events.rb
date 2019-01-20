module Peatio::Injectors
  class PeatioEvents
    attr_accessor :market, :market_name, :base_unit, :quote_unit, :seller_uid, :buyer_uid, :logger

    def run!
      require "time"
      @logger = Peatio::Logger.logger
      @market = "eurusd"
      @market_name = "EUR/USD"
      @base_unit = "eur"
      @quote_unit = "usd"
      @seller_uid = 21
      @buyer_uid = 42
      @messages = create_messages
      @exchange_name = "peatio.events.market"

      EventMachine.run do
        Peatio::MQ::Client.new
        Peatio::MQ::Client.connect!
        Peatio::MQ::Client.create_channel!
        inject_message
      end
    end

    def inject_message
      if message = @messages.shift
        type, id, event, data = message
        Peatio::MQ::Events.publish(type, id, event, data) {
          inject_message
        }
      else
        Peatio::MQ::Client.disconnect { EventMachine.stop }
      end
    end

    def create_messages
      [
        public_tickers,
        public_orderbook,
        private_order,
        private_trade_user1,
        private_trade_user2,
        public_trade,
      ]
    end

    def created_at
      Time.now - 600
    end

    def updated_at
      Time.now
    end

    alias :completed_at :updated_at
    alias :canceled_at :updated_at

    def public_orderbook
      [
        "public",
        market,
        "update",
        {
          "asks": [
            ["1020.0","0.005"],
            ["1026.0","0.03"]
          ],
          "bids": [
            ["1000.0","0.25"],
            ["999.0","0.005"],
            ["994.0","0.005"],
            ["1.0","11.0"]
          ]
        }
      ]
    end

    def public_tickers
      [
        "public",
        "global",
        "tickers",
        {
          market => {
            "name": market_name,
            "base_unit": base_unit,
            "quote_unit": quote_unit,
            "low": "1000.0",
            "high": "10000.0",
            "last": "1000.0",
            "open": 1000.0,
            "volume": "0.0",
            "sell": "1020.0",
            "buy": "1000.0",
            "at": Time.now.to_i
            }
          }
      ]
    end

    def private_order
      [
        "private",
        "IDABC0000001",
        "order",
        {
          "id": 22,
          "at": created_at.to_i,
          "market": market,
          "kind":"bid",
          "price":"1026.0",
          "state":"wait",
          "volume":"0.001",
          "origin_volume":"0.001"
        }
      ]
    end

    def private_trade_user1
      [
        "private",
        "IDABC0000001",
        "trade",
        {
          "id": 7,
          "kind": "ask",
          "at": created_at.to_i,
          "price": "1020.0",
          "volume": "0.001",
          "ask_id": 15,
          "bid_id": 22,
          "market": market
        }
      ]
    end

    def private_trade_user2
      [
        "private",
        "IDABC0000002",
        "trade",
        {
          "id": 7,
          "kind": "bid",
          "at": created_at.to_i,
          "price": "1020.0",
          "volume": "0.001",
          "ask_id": 15,
          "bid_id": 22,
          "market": market
        }
      ]
    end

    def public_trade
      [
        "public",
        market,
        "trades",
        {
          "trades": [
            {
              "tid": 7,
              "type": "buy",
              "date": created_at.to_i,
              "price": "1020.0",
              "amount":
              "0.001"
            }
          ]
        }
      ]
    end

  end
end
