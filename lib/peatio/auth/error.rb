module Peatio::Auth
  class Error < Peatio::Error
    attr_reader :reason

    def initialize(reason = nil)
      @reason = reason

      super(
        code: 2001,
        text: "Authorization failed: #{reason}",
        status: 401,
      )
    end
  end
end
