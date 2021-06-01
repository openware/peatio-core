require 'active_support/concern'
require 'active_support/core_ext/string/inquiry'
require 'active_support/core_ext/object/blank'
require 'active_model'

module Peatio #:nodoc:

  # This class represents blockchain transaction.
  #
  # Using the instant of this class the peatio application will send/recieve
  # income/outcome transactions from a peatio pluggable blockchain.
  #
  # @example
  #
  #   Peatio::Transaction.new(
  #     {
  #       hash: '0x5d0ef9697a2f3ea561c9fbefb48e380a4cf3d26ad2be253177c472fdd0e8b486',
  #       txout: 1,
  #       to_address: '0x9af4f143cd5ecfba0fcdd863c5ef52d5ccb4f3e5',
  #       amount: 0.01,
  #       fee: 0.0004,
  #       block_number: 7732274,
  #       currency_id: 'eth',
  #       fee_currency_id: 'eth',
  #       status: 'success'
  #     }
  #   )
  #
  # @author
  #   Maksym Naichuk <naichuk.maks@gmail.com> (https://github.com/mnaichuk)
  class Transaction
    include ActiveModel::Model

    # List of statuses supported by peatio.
    #
    # @note Statuses list:
    #
    #   pending - the transaction is unconfirmed in the blockchain or
    #   wasn't created yet.
    #
    #   success - the transaction is a successfull,
    #   the transaction amount has been successfully transferred
    #
    #   failed - the transaction is failed in the blockchain.
    #
    #   rejected - the transaction is rejected by user.

    STATUSES = %w[success pending failed rejected].freeze

    DEFAULT_STATUS = 'pending'.freeze

    # @!attribute [rw] hash
    # return [String] transaction hash
    attr_accessor :hash

    # @!attribute [rw] txout
    # return [Integer] transaction number in send-to-many request
    attr_accessor :txout

    # @!attribute [rw] from_address
    # return [Array<String>] transaction source addresses
    attr_accessor :from_addresses

    # @!attribute [rw] to_address
    # return [String] transaction recepient address
    attr_accessor :to_address

    # @!attribute [rw] amount
    # return [Decimal] amount of the transaction
    attr_accessor :amount

    # @!attribute [rw] fee
    # return [Decimal] fee of the transaction
    attr_accessor :fee

    # @!attribute [rw] block_number
    # return [Integer] transaction block number
    attr_accessor :block_number

    # @!attribute [rw] currency_id
    # return [String] transaction currency id
    attr_accessor :currency_id

    # @!attribute [rw] fee_currency_id
    # return [String] transaction fee currency id
    attr_accessor :fee_currency_id

    # @!attribute [rw] options
    # return [JSON] transaction options
    attr_accessor :options

    validates :to_address,
              :amount,
              :currency_id,
              :status,
              presence: true

    validates :hash,
              :block_number,
              presence: { if: -> (t){ t.status.failed? || t.status.success? } }

    validates :txout,
              presence: { if: -> (t){ t.status.success? } }

    validates :block_number,
              numericality: { greater_than_or_equal_to: 0, only_integer: true }

    validates :amount,
              numericality: { greater_than_or_equal_to: 0 }

    validates :fee,
              numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

    validates :status, inclusion: { in: STATUSES }

    def initialize(attributes={})
      super
      @status = @status.present? ? @status.to_s : DEFAULT_STATUS
    end

    # Status for specific transaction.
    #
    # @!method status
    #
    # @example
    #
    #   status.failed? # true if transaction status 'failed'
    #   status.success? # true if transaction status 'success'
    def status
      @status&.inquiry
    end

    def status=(s)
      @status = s.to_s
    end
  end
end
