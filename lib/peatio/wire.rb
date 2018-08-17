module Peatio
  class Wire
    def emit(message, *args)
      @wire_callbacks = {} if @wire_callbacks.nil?

      if !@wire_callbacks[message].nil?
        @wire_callbacks[message].each { |block|
          block.yield(*args)
        }
      end
    end

    def on(message, &block)
      @wire_callbacks = {} if @wire_callbacks.nil?
      @wire_callbacks[message] = [] if @wire_callbacks[message].nil?
      @wire_callbacks[message] << block
    end
  end
end
