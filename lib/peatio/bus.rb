module Peatio
  # Module Bus provides mixin for inclusion into other classes to provide
  # event-based callbacks.
  #
  # Suitable for working inside EventMachine loop.
  module Bus
    # Method yields all blocks that bound on previous {on} method calls with
    # given arguments.
    #
    # @param message [Symbol] Message identifier to emit.
    # @param args [Array<Any>] Arguments to pass to callback block.
    #
    # @see on
    def emit(message, *args)
      @bus_callbacks = {} if @bus_callbacks.nil?

      if !@bus_callbacks[message].nil?
        @bus_callbacks[message].each { |block|
          block.yield(*args)
        }
      end
    end

    # Method adds given block as callback for given message identifier.
    #
    # @param message [Symbol] Message identifier to listen.
    # @yield [Any, ...] Block that will be yielded with arguments passed by {emit}.
    #
    # @see emit
    def on(message, &block)
      @bus_callbacks = {} if @bus_callbacks.nil?
      @bus_callbacks[message] = [] if @bus_callbacks[message].nil?
      @bus_callbacks[message] << block
    end
  end
end
