module Peatio::Command
  class Inject < Peatio::Command::Base
    class PeatioEvents < Peatio::Command::Base
      option ["-e", "--exchange"], "NAME", "exchange name to inject messages to", default: "peatio.events.ranger"
      def execute
        Peatio::Logger.logger.level = :debug
        Peatio::Injectors::PeatioEvents.new.run!(exchange)
      end
    end

    subcommand "peatio_events", "Inject peatio events in mq", PeatioEvents
  end
end
