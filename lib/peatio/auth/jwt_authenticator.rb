require "jwt"

require_relative "error"

module Peatio::Auth
  # JWTAuthenticator used to authenticate user using JWT.
  #
  # It allows configuration of JWT verification through following ENV
  # variables (all optional):
  # * JWT_ISSUER
  # * JWT_AUDIENCE
  # * JWT_ALGORITHM (default: RS256)
  # * JWT_DEFAULT_LEEWAY
  # * JWT_ISSUED_AT_LEEWAY
  # * JWT_EXPIRATION_LEEWAY
  # * JWT_NOT_BEFORE_LEEWAY
  #
  # @see https://github.com/jwt/ruby-jwt JWT validation parameters.
  #
  # @example Token validation
  #   rsa_private = OpenSSL::PKey::RSA.generate(2048)
  #   rsa_public = rsa_private.public_key
  #
  #   payload = {
  #     iat: Time.now.to_i,
  #     exp: (Time.now + 60).to_i,
  #     sub: "session",
  #     iss: "barong",
  #     aud: [
  #       "peatio",
  #       "barong",
  #     ],
  #     jti: "BEF5617B7B2762DDE61702F5",
  #     uid: "TEST123",
  #     email: "user@example.com",
  #     role: "admin",
  #     level: 4,
  #     state: "active",
  #   }
  #
  #   token = JWT.encode(payload, rsa_private, "RS256")
  #
  #   auth = Peatio::Auth::JWTAuthenticator.new(rsa_public)
  #   auth.authenticate!("Bearer #{token}")
  class JWTAuthenticator
    # Creates new authenticator with given public key.
    #
    # @param public_key [OpenSSL::PKey::PKey] Public key object to verify
    #   signature.
    # @param private_key [OpenSSL::PKey::PKey] Optional private key that used
    #   only to encode new tokens.
    def initialize(public_key, private_key = nil)
      @public_key = public_key
      @private_key = private_key

      @verify_options = {
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

      @encode_options = {
        algorithm: @verify_options[:algorithms].first,
      }.compact
    end

    # Decodes and verifies JWT.
    # Returns payload from JWT or raises an exception
    #
    # @param token [String] Token string. Must start from <tt>"Bearer "</tt>.
    # @return [Hash] Payload Hash from JWT without any changes.
    #
    # @raise [Peatio::Auth::Error] If token is invalid or can't be verified.
    def authenticate!(token)
      token_type, token_value = token.to_s.split(" ")

      unless token_type == "Bearer"
        raise(Peatio::Auth::Error, "Token type is not provided or invalid.")
      end

      decode_and_verify_token(token_value)
    rescue => error
      case error
      when Peatio::Auth::Error
        raise(error)
      else
        raise(Peatio::Auth::Error, error.message)
      end
    end

    # Encodes given payload and produces JWT.
    #
    # @param payload [String, Hash] Payload to encode.
    # @return [String] JWT token string.
    #
    # @raise [ArgumentError] If no private key was passed to constructor.
    def encode(payload)
      raise(::ArgumentError, "No private key given.") if @private_key.nil?

      JWT.encode(payload, @private_key, @encode_options[:algorithm])
    end

    private

    def decode_and_verify_token(token)
      payload, header = JWT.decode(token, @public_key, true, @verify_options)

      payload.keys.each { |k| payload[k.to_sym] = payload.delete(k) }

      payload
    rescue JWT::DecodeError => e
      raise(Peatio::Auth::Error, "Failed to decode and verify JWT: #{e.message}")
    end
  end
end
