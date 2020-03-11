# frozen_string_literal: true

describe Peatio::Upstream::Base do
  let(:trade_event) {
    {
      "tid"        => 239_434_269,
      "taker_type" => "sell",
      "date"       => 1_583_923_698,
      "price"      => "7818.40000000",
      "amount"     => "0.00275200"
    }
  }

  let(:upstream_config) do
    {
      "driver":    "bitfinex",
      "source":    "btcusd",
      "target":    "btcusd",
      "rest":      "http://api-pub.bitfinex.com/ws/2",
      "websocket": "wss://api-pub.bitfinex.com/ws/2"
    }.stringify_keys
  end

  let(:upstream) { Peatio::Upstream::Base.new(upstream_config) }
  let(:trade_msg) {
    {
      amount:     "0.00275200",
      created_at: "2020-03-11T12:48:18+02:00",
      id:         239_434_269,
      market_id:  "btcusd",
      price:      "7818.40000000",
      taker_type: "sell",
    }
  }

  context "#trade_json" do
    it do
      expect(upstream.trade_json(trade_event)).to eq(trade_msg)
    end
  end
end
