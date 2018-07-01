module Peatio::Command::Service

  class Start < Peatio::Command::Base

    parameter "NAME", "Start service NAME", attribute_name: :service
    def execute
      say "Start #{service}"
    end
  end

  class Stop < Peatio::Command::Base

    parameter "NAME", "Stop service NAME", attribute_name: :service
    def execute
      say "Stop #{service}"
    end
  end

  class List < Peatio::Command::Base

    def execute
      say "engine"
    end
  end

  class Root < Peatio::Command::Base

    subcommand "start", "Start a service", Start
    subcommand "stop", "Stop a service", Stop
    subcommand "list", "List services", List
  end

end
