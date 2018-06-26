require "peatio/db"
require "peatio/amqp"
require "peatio/service"

module Peatio
  class Root < Clamp::Command
    subcommand "amqp", "AMQP related sub-commands", Peatio::Amqp::Root
    subcommand "db", "Database related sub-commands", Peatio::Db::Root
    subcommand "service", "Services management related sub-commands", Peatio::Service::Root
  end
end
