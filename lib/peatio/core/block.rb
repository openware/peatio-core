module Peatio #:nodoc:

  # This class represents blockchain block which contains transactions.
  #
  # Using instant of this class in return for Peatio::Core::Blockchain#fetch_block!
  # @see Peatio::Core::Blockchain#fetch_block! example implementation
  #     (inside peatio source https://github.com/rubykube/peatio)
  #
  # @author
  #   Maksym Naichuk <naichuk.maks@gmail.com> (https://github.com/mnaichuk)
  module Core
    class Block
      include Enumerable

      delegate :each, to: :@transactions

      # @!attribute [r] number
      # return [String] block number
      attr_reader :number

      # @!attribute [r] transactions
      # return [Array<Peatio::Core::Transaction>]
      attr_reader :transactions

      def initialize(number, transactions)
        @number = number
        @transactions = transactions
      end
    end
  end
end
