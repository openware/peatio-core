module Peatio::BlockchainClient
  # TODO: Inspect if we need this class.
  class Base
    #
    # Returns the blockchain.
    #
    # @return [blockchain]
    attr_reader :blockchain

    def initialize(blockchain)
      @blockchain = blockchain
    end

    #
    # Returns hot wallet balance.
    #
    # @abstract Derived API clients must implement it.
    #
    # @param currency [String, Symbol]
    # @return [BigDecimal]
    def load_balance!(currency)
      method_not_implemented
    end

    #
    # Returns transaction details.
    #
    # TODO: Docs.
    #
    # @param txid [String]
    # @return [Hash]
    #   The deposit details.
    def load_deposit!(txid)
      method_not_implemented
    end

    def convert_to_base_unit!(value)
      x = value.to_d * blockchain.base_factor
      unless (x % 1).zero?
        raise BlockchainClient::Error, "Failed to convert value to base (smallest) unit because it exceeds the maximum precision: " +
          "#{value.to_d} - #{x.to_d} must be equal to zero."
      end
      x.to_i
    end

    def convert_from_base_unit(value, currency)
      value.to_d / currency.base_factor
    end

    def normalize_address(address)
      case_sensitive? ? address : address.try(:downcase)
    end

    def normalize_txid(txid)
      case_sensitive? ? txid : txid.try(:downcase)
    end

    # IMPORTANT: Be sure to set the correct value!
    def case_sensitive?
      true
    end

    # IMPORTANT: Be sure to set the correct value!
    def supports_cash_addr_format?
      false
    end
  end
end