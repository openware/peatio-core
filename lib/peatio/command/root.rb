
require "peatio/command/base"
require "peatio/command/service"
require "peatio/command/db"
require "peatio/command/amqp"

module Peatio
  class Root < Command::Base
    subcommand "amqp", "AMQP related sub-commands", Peatio::Command::AMQP::Root
    subcommand "db", "Database related sub-commands", Peatio::Command::DB::Root
    subcommand "service", "Services management related sub-commands", Peatio::Command::Service::Root
  end
end
