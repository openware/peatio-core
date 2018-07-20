module Peatio::MQ
  class Client
    class << self
      attr_reader :channel

      def new(options = {})
        @connection = AMQP.connect(options)
        @channel = AMQP::Channel.new(@connection)
      end
    end
  end
end
