require "jwt"

require_relative "error"

module Peatio::Auth
  class JWTAuthenticator
    @@verify_options = {
      verify_expiration: true,
      verify_not_before: true,
      iss: ENV["JWT_ISSUER"],
      verify_iss: !ENV["JWT_ISSUER"].nil?,
      verify_iat: true,
      verify_jti: true,
      aud: ENV["JWT_AUDIENCE"].to_s.split(",").reject(&:empty?),
      verify_aud: !ENV["JWT_AUDIENCE"].nil?,
      sub: "session",
      verify_sub: true,
      algorithms: [ENV["JWT_ALGORITHM"] || "RS256"],
      leeway: ENV["JWT_DEFAULT_LEEWAY"].yield_self { |n| n.to_i unless n.nil? },
      iat_leeway: ENV["JWT_ISSUED_AT_LEEWAY"].yield_self { |n| n.to_i unless n.nil? },
      exp_leeway: ENV["JWT_EXPIRATION_LEEWAY"].yield_self { |n| n.to_i unless n.nil? },
      nbf_leeway: ENV["JWT_NOT_BEFORE_LEEWAY"].yield_self { |n| n.to_i unless n.nil? },
    }.compact

    def initialize(token, public_key)
      @token_type, @token_value = token.to_s.split(" ")
      @public_key = public_key
    end

    # Decodes and verifies JWT.
    # Returns authentic member email or raises an exception.
    #
    # @param [Hash] options
    # @return [String, Member, NilClass]
    def authenticate!(options = {})
      unless @token_type == "Bearer"
        raise(Peatio::Auth::Error, "Token type is not provided or invalid.")
      end

      decode_and_verify_token(@token_value)
    rescue => e
      if Peatio::Auth::Error === e
        raise e
      else
        raise Peatio::Auth::Error, e.inspect
      end
    end

    private

    def decode_and_verify_token(token)
      payload, header = JWT.decode(token, @public_key, true, @@verify_options)

      payload.keys.each { |k| payload[k.to_sym] = payload.delete(k) }

      payload
    rescue JWT::DecodeError => e
      raise Peatio::Auth::Error, "Failed to decode and verify JWT: #{e.inspect}."
    end
  end
end
