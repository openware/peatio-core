module Peatio::Command
  class Inject < Peatio::Command::Base
    class PeatioEvents < Peatio::Command::Base
      def execute
        Peatio::Injectors::PeatioEvents.new.run!
      end
    end

    subcommand "peatio_events", "Inject peatio events in mq", PeatioEvents
  end
end
