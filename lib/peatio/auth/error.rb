module Peatio::Auth
  # Error repesent all errors that can be returned from Auth module.
  class Error < Peatio::Error
    # @return [String, JWT::*] Reason store underlying reason for given error.
    #
    # @see https://github.com/jwt/ruby-jwt/blob/master/lib/jwt/error.rb List of JWT::* errors.
    attr_reader :reason

    def initialize(reason = nil)
      @reason = reason

      super(
        code: 2001,
        text: "Authorization failed".tap { |t| t << ": #{reason}" if reason },
      )
    end
  end
end
