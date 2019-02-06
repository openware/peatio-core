module Peatio::BlockchainClient
  # TODO: Inspect if we need this class.
  module Helpers

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

    # def normalize_address(address)
    #   case_sensitive? ? address : address.try(:downcase)
    # end
    #
    # def normalize_txid(txid)
    #   case_sensitive? ? txid : txid.try(:downcase)
    # end
  end
end
