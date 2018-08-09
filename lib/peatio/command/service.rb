module Peatio::Command::Service

  class Start < Peatio::Command::Base
    class Ranger < Peatio::Command::Base
      def execute
        ::Peatio::Ranger.run!
      end
    end

    subcommand "ranger", "Start ranger process", Ranger
  end

  class Root < Peatio::Command::Base
    subcommand "start", "Start a service", Start
  end

end
