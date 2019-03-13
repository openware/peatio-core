module Peatio::Command::AMQP
  class Root < Peatio::Command::Base

    class Inspector < Peatio::Command::Base
      def execute
        Peatio::MQ::Inspector.new.run!
      end
    end

    subcommand "inspector", "Inspect  events in mq", Inspector
  end
end
