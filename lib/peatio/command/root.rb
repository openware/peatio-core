# frozen_string_literal: true

require "peatio/command/base"
require "peatio/command/service"
require "peatio/command/db"
require "peatio/command/amqp"
require "peatio/command/inject"
require "peatio/command/test"

module Peatio
  class Root < Command::Base
    subcommand "amqp", "AMQP related sub-commands", Peatio::Command::AMQP::Root
    subcommand "db", "Database related sub-commands", Peatio::Command::DB::Root
    subcommand "service", "Services management related sub-commands", Peatio::Command::Service::Root
    subcommand "test", "Run various test tools", Peatio::Command::Test::Root
    subcommand "inject", "Data injectors", Peatio::Command::Inject
  end
end
