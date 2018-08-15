module Peatio::Auth
  # Error repesent all errors that can be returned from Auth module.
  class Error < Peatio::Error
    # Reason store underlying reason for given error.
    #
    # Can be:
    # * string
    # * JWT::*[https://github.com/jwt/ruby-jwt/blob/master/lib/jwt/error.rb] error
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
