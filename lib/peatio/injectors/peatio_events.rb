module Peatio::Injectors
  class PeatioEvents
    attr_accessor :market, :seller_uid, :buyer_uid, :logger

    def run!
      require "time"
      @logger = Peatio::Logger.logger
      @market = "eurusd"
      @seller_uid = 21
      @buyer_uid = 42
      @messages_group = create_messages
      @exchange_name = "peatio.events.market"

      EventMachine.run do
        Peatio::MQ::Client.new
        Peatio::MQ::Client.connect!
        Peatio::MQ::Client.create_channel!
        inject_message
      end
    end

    def inject_message
      @messages_group.each do |group|
        #if message = @messages.shift
        group[1].each do |message|
          id, event, data = message
          Peatio::MQ::Events.inject_events(group[0], id, event, data)
        end
      end
        Peatio::MQ::Client.disconnect { EventMachine.stop }
    end

    def create_messages
      #  private_trade,
      {
        'peatio.events.market': [
          order_created,
          order_canceled,
          order_completed,
          order_updated,
          trade_completed
        ],
        'peatio.events.model': [
          account_created,
          account_updated,
          deposit_created,
          deposit_updated,
          withdraw_created,
          withdraw_updated
        ]
      }
    end

    def created_at
      Time.now - 600
    end

    def updated_at
      Time.now
    end

    alias :completed_at :updated_at
    alias :canceled_at :updated_at

#    def private_trade
#      [
#        "private",
#        "debug_user",
#        "trade",
#        {
#          trade: "some-data",
#        },
#      ]
#    end

    def order_created
      [
        market,
        "order_created",
        {
          id: 1,
          market: "#{market}",
          type: "buy",
          trader_uid: buyer_uid,
          income_unit: "btc",
          income_fee_type: "relative",
          income_fee_value: "0.0015",
          outcome_unit: "usd",
          outcome_fee_type: "relative",
          outcome_fee_value: "0.0",
          initial_income_amount: "14.0",
          current_income_amount: "14.0",
          initial_outcome_amount: "0.42",
          current_outcome_amount: "0.42",
          strategy: "limit",
          price: "0.03",
          state: "open",
          trades_count: 0,
          created_at: created_at.iso8601,
          name: "market.#{market}.order_created"
        },
      ]
    end

    def order_canceled
      [
        market,
        "order_canceled",
        {
          id: 2,
          market: "#{market}",
          type: "sell",
          trader_uid: seller_uid,
          income_unit: "usd",
          income_fee_type: "relative",
          income_fee_value: "0.0015",
          outcome_unit: "btc",
          outcome_fee_type: "relative",
          outcome_fee_value: "0.0",
          initial_income_amount: "3.0",
          current_income_amount: "3.0",
          initial_outcome_amount: "100.0",
          current_outcome_amount: "100.0",
          strategy: "limit",
          price: "0.03",
          state: "canceled",
          trades_count: 0,
          created_at: created_at.iso8601,
          canceled_at: canceled_at.iso8601,
          name: "market.#{market}.order_canceled"
        },
      ]
    end

    def order_completed
      [
        market,
        "order_completed", {
          id: 1,
          market: "#{market}",
          type: "sell",
          trader_uid: seller_uid,
          income_unit: "usd",
          income_fee_type: "relative",
          income_fee_value: "0.0015",
          outcome_unit: "btc",
          outcome_fee_type: "relative",
          outcome_fee_value: "0.0",
          initial_income_amount: "3.0",
          current_income_amount: "0.0",
          previous_income_amount: "3.0",
          initial_outcome_amount: "100.0",
          current_outcome_amount: "0.0",
          previous_outcome_amount: "100.0",
          strategy: "limit",
          price: "0.03",
          state: "completed",
          trades_count: 1,
          created_at: created_at.iso8601,
          completed_at: completed_at.iso8601,
          name: "market.#{market}.order_completed"
        },
      ]
    end

    def order_updated
      [
        market,
        "order_updated", {
          id: 1,
          market: "#{market}",
          type: "sell",
          trader_uid: seller_uid,
          income_unit: "usd",
          income_fee_type: "relative",
          income_fee_value: "0.0015",
          outcome_unit: "btc",
          outcome_fee_type: "relative",
          outcome_fee_value: "0.0",
          initial_income_amount: "3.0",
          current_income_amount: "2.4",
          previous_income_amount: "3.0",
          initial_outcome_amount: "100.0",
          current_outcome_amount: "80.0",
          previous_outcome_amount: "100.0",
          strategy: "limit",
          price: "0.03",
          state: "open",
          trades_count: 1,
          created_at: created_at.iso8601,
          updated_at: updated_at.iso8601,
          name: "market.#{market}.order_updated"
        },
      ]
    end

    def trade_completed
      [
        market,
        "trade_completed", {
          id: 1,
          market: "#{market}",
          price: "0.03",
          buyer_uid: buyer_uid,
          buyer_income_unit: "btc",
          buyer_income_amount: "14.0",
          buyer_income_fee: "0.021",
          buyer_outcome_unit: "usd",
          buyer_outcome_amount: "0.42",
          buyer_outcome_fee: "0.0",
          seller_uid: seller_uid,
          seller_income_unit: "usd",
          seller_income_amount: "0.42",
          seller_income_fee: "0.00063",
          seller_outcome_unit: "btc",
          seller_outcome_amount: "14.0",
          seller_outcome_fee: "0.0",
          completed_at: completed_at.iso8601,
          name: "market.#{market}.trade_completed"
        },
      ]
    end

    def account_created
      [
        'account',
        'created', {
            id: 12,
            member_id: 5, currency_id: "usd",
            balance: "0.0",
            locked:"0.0",
            created_at: created_at.iso8601,
            updated_at: updated_at.iso8601
        }
      ]
    end

    def account_updated
      [
        'account',
        'updated', {
            id: 12,
            member_id: 5, currency_id: "usd",
            balance: "0.0",
            locked:"0.0",
            created_at: created_at.iso8601,
            updated_at: updated_at.iso8601
        }
      ]
    end

    def deposit_created
      [
        'deposit',
        'created', {
          tid:                      'TIDE7A9CCAEA8',
          uid:                      'IDE7FBEDB382',
          currency:                 'ltc',
          amount:                   '0.099',
          state:                    'accepted',
          created_at:               created_at.iso8601,
          updated_at:               updated_at.iso8601,
          completed_at:             completed_at.iso8601,
          blockchain_address:       'QbJtG5EorumddWVN2t8wuh5tXWSKMuNjj4',
          blockchain_txid:          '93369cefe5ad5103509de1043b1712371d39d290921f62f8ad7cbd6a0f55e1b7'
        }
      ]
    end

    def deposit_updated
      [
        'deposit',
        'updated', {
          tid:                      'TIDE7A9CCAEA8',
          uid:                      'IDE7FBEDB382',
          currency:                 'ltc',
          amount:                   '0.099',
          state:                    'accepted',
          created_at:               created_at.iso8601,
          updated_at:               updated_at.iso8601,
          completed_at:             completed_at.iso8601,
          blockchain_address:       'QbJtG5EorumddWVN2t8wuh5tXWSKMuNjj4',
          blockchain_txid:          '93369cefe5ad5103509de1043b1712371d39d290921f62f8ad7cbd6a0f55e1b7'
        }
      ]
    end

    def withdraw_created
      [
        'withdraw',
        'created', {
          tid:             'TIDE7A9CCAEA8',
          uid:             'IDE7FBEDB382',
          rid:             '0x007b45e69c49d9b0f583d2ff42afdbdf95b56744',
          currency:        'ltc',
          amount:          '0.099',
          fee:             '0.009',
          state:           'succeed',
          created_at:      created_at.iso8601,
          updated_at:      updated_at.iso8601,
          completed_at:    completed_at&.iso8601,
          blockchain_txid: '93369cefe5ad5103509de1043b1712371d39d290921f62f8ad7cbd6a0f55e1b7'
        }
      ]
    end

    def withdraw_updated
      [
        'withdraw',
        'updated', {
          tid:             'TIDE7A9CCAEA8',
          uid:             'IDE7FBEDB382',
          rid:             '0x007b45e69c49d9b0f583d2ff42afdbdf95b56744',
          currency:        'ltc',
          amount:          '0.099',
          fee:             '0.009',
          state:           'succeed',
          created_at:      created_at.iso8601,
          updated_at:      updated_at.iso8601,
          completed_at:    completed_at&.iso8601,
          blockchain_txid: '93369cefe5ad5103509de1043b1712371d39d290921f62f8ad7cbd6a0f55e1b7'
        }
      ]
    end
  end
end
