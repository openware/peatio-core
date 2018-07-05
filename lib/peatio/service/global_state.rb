require "peatio/service/base_service"

require "peatio/service/global_state/em"
require "peatio/service/global_state/amqp"

module Peatio::Service
  module GlobalState
    extend BaseService

    register("global-state") do
      puts "Running global-state daemon"
      #
      # GlobalState::EM.run!
      # GlobalState::AMQP.run!
      #
    end
  end
end
