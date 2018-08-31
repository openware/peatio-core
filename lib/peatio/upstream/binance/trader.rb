# Class provides API for non-blocking submitting order for execution with
# timeout.
class Peatio::Upstream::Binance::Trader
  # Class provides simple event object for subscribing on events after order
  # is submitted for execution.
  #
  # Use {Bus} methods to subscribe on following events:
  # * +:error+ +|request|+: error while submitting order via REST API. Raw
  #   EventMachine HttpRequest will be passed as block argument.
  # * +:submitted+ +|id|+: order successfully submitted for execution and was
  #   asssigned +id+.
  # * +:partially_filled+ +|quantity, price|+: order partially filled for
  #   given +quantity+ and +price+.
  # * +:filled+ +|quantity, price|+: order was fully filled with for
  #   +quantity+ and +price+.
  #   {quantity}.
  # * +:canceled+: order canceled. Amount that left untraded can be
  #   retrieved from {quantity} attribute.
  #
  # For example usage see {Trader.order} example.
  #
  # @see EM::HttpRequest
  class Order
    include Peatio::Bus

    # Market order was placed on.
    attr_accessor :symbol

    # Order type, like +MARKET+ or +LIMIT+.
    attr_accessor :type

    # Order side, like +BUY+ or +SELL+.
    attr_accessor :side

    # Quantity that left in order yet untraded.
    #
    # Value of this attribute *can* *change* during execution.
    attr_accessor :quantity

    # Price order was created with, can be zero.
    attr_accessor :price

    # @!visibility protected
    attr_accessor :timer

    # @!visibility protected
    def initialize(symbol, type, side, quantity, price)
      @symbol = symbol
      @type = type
      @side = side
      @quantity = quantity
      @price = price
    end
  end

  # Method creates and places order for execution with given timeout.
  #
  # If order is not fulfiled after specified amount, then it will be canceled.
  #
  # Method is non-blocking and will return {Order} object to subscribe on
  # all events related to trading.
  #
  # Timeout can be set to 0 which makes order to be submitted with IOC flag
  # (Immediate or Cancel). That order either will be fullfiled (maybe
  # partially) or canceled immediately.
  #
  # Method should be invoked inside +EM.run{}+ loop
  #
  # @example
  #   EM.run {
  #     binance = Peatio::Upstream::Binance.new
  #
  #     order = binance.trader.order(
  #       timeout: 5,
  #       symbol: "TUSDBTC",
  #       type: "LIMIT",
  #       side: "BUY",
  #       quantity: 100,
  #       price: 0.000143,
  #     )
  #
  #     order.on :error do |request|
  #       puts("order error: #{request.response}")
  #       EM.stop
  #     end
  #
  #     order.on :submitted do |id|
  #       puts("order submitted: #{id}")
  #     end
  #
  #     order.on :partially_filled do |quantity, price|
  #       puts("order partially filled: #{quantity} #{price}")
  #     end
  #
  #     order.on :filled do |quantity, price|
  #       puts("order filled: #{quantity} #{price}")
  #       EM.stop
  #     end
  #
  #     order.on :canceled do
  #       puts("order canceled: #{order.quantity} left")
  #       EM.stop
  #     end
  #   }
  #
  # @param timeout [Integer] Timeout in seconds before order is canceled.
  # @param symbol [String] Symbol to trade one.
  # @param type [String] Order type: +MARKET+ or +LIMIT+.
  # @param quantity [Float] Quantity for trade.
  # @param price [Float] Price for given order. Ignored for +MARKET+ orders.
  #
  # @return [Order] Order object with {Bus} interface.
  def order(timeout:, symbol:, type:, side:, quantity:, price:)
    order = Order.new(symbol, type, side, quantity, price)

    @client.connect_private_stream! { |stream|
      stream.on :error do |message|
        logger.error "error while listening for private stream: #{message}"
      end

      stream.on :open do |event|
        submit_order(timeout, order, stream)
      end

      stream.on :message do |message|
        payload = JSON.parse(message.data)
        event = payload["e"]

        case event
        when "executionReport"
          process_execution_report(payload, order, stream)
        end
      end
    }

    order
  end

  protected

  def initialize(client)
    @client = client
    @ready = false
    @open_orders = {}
  end

  private

  def logger
    Peatio::Upstream::Binance.logger
  end

  def submit_order(timeout, order, stream)
    logger.info "[#{order.symbol.downcase}] submitting new order: " \
                "#{order.type} #{order.side} " \
                "amount=#{order.quantity} price=#{order.price || "<empty>"}"

    time_in_force = "GTC"
    if timeout == 0
      time_in_force = "IOC"
    end

    request = @client.submit_order(
      symbol: order.symbol,
      side: order.side,
      type: order.type,
      quantity: order.quantity,
      price: order.price,
      time_in_force: time_in_force,
    )

    request.errback {
      order.emit(:error, request)
    }

    request.callback {
      if request.response_header.status >= 300
        order.emit(:error, request)
      else
        payload = JSON.parse(request.response)

        id = payload["orderId"]

        logger.info "[#{order.symbol.downcase}] ##{id} order submitted: " \
                    "#{order.type} #{order.side} " \
                    "amount=#{order.quantity} price=#{order.price || "<empty>"}"

        @open_orders[id] = order

        if timeout > 0
          order.timer = EM::add_timer(timeout) {
            logger.info "[#{order.symbol.downcase}] ##{id} cancelling order: " \
                        "timeout expired: #{timeout} seconds"

            request = @client.cancel_order(symbol: order.symbol, id: id)

            request.errback {
              order.emit(:error, request)
              stream.close
            }

            request.callback {
              @open_orders.delete(id)
              order.emit(:canceled)
            }
          }
        end

        order.emit(:submitted, id)
      end
    }
  end

  def process_execution_report(data, order, stream)
    symbol = data["s"]
    id = data["i"]
    event, order_status = data["x"], data["X"]
    price = data["L"]

    quantity_filled, quantity_total = data["l"], data["q"]
    quantity_traded = data["z"]

    if id < 0
      logger.error "[#{symbol.downcase}] order execution error: event=#{event}"
      return
    end

    order.on(:submitted) {
      logger.debug "[#{symbol.downcase}] ##{id} order execution report: " \
                   "event=#{event} order_status=#{order_status} " \
                   "quantity=#{quantity_filled} (#{quantity_traded}/#{quantity_total})"

      close = process(
        id,
        order_status.downcase.to_sym,
        quantity_filled.to_i,
        price
      )

      stream.close if close
    }
  end

  def process(id, status, quantity, price)
    order = @open_orders[id]
    if order.nil?
      logger.fatal "received order event for unknown order ##{id}"
      return
    end

    case status
    when :partially_filled
      order.quantity -= quantity
      order.emit(status, quantity, price)
    when :filled
      order.quantity = 0
      order.emit(status, quantity, price)
      EM.cancel_timer(order.timer)
      @open_orders.delete(id)
      return true
    when :canceled
      order.emit(status)
      EM.cancel_timer(order.timer)
      @open_orders.delete(id)
      return true
    when :expired
      order.emit(:canceled)
      EM.cancel_timer(order.timer)
      @open_orders.delete(id)
      return true
    end
  end
end
