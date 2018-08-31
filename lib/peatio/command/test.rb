# frozen_string_literal: true

# Module provides commands that can be used to run various test tools from CLI:
#
# @example
#   bin/peatio test [...]
# @see Upstream
module Peatio::Command::Test
  require_relative "test/upstream"

  # @!visibility protected
  class Root < Peatio::Command::Base
    subcommand "upstream", "Upstream testing tools", Upstream::Root
  end
end
