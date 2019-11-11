require "peatio/command/base"
require "peatio/command/service"
require "peatio/command/db"
require "peatio/command/inject"
require "peatio/command/security"

module Peatio
  class Root < Command::Base
    subcommand "db", "Database related sub-commands", Peatio::Command::DB::Root
    subcommand "service", "Services management related sub-commands", Peatio::Command::Service::Root
    subcommand "inject", "Data injectors", Peatio::Command::Inject
    subcommand "security", "Security management related sub-commands", Peatio::Command::Security
  end
end
