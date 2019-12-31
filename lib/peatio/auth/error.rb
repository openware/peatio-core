# frozen_string_literal: true

module Peatio::Auth
  # Error represent all errors that can be returned from Auth module.
  class Error < Peatio::Error
    # @return [String, JWT::*] Reason store underlying reason for given error.
    #
    # @see https://github.com/jwt/ruby-jwt/blob/master/lib/jwt/error.rb List of JWT::* errors.
    attr_reader :reason

    def initialize(reason = nil)
      @reason = reason

      super(
        code: 2001,
        text: %[Authorization failed#{": #{reason}" if reason.present?}]
      )
    end
  end
end
