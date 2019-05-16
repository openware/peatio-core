module Peatio #:nodoc:
  module Blockchain #:nodoc:

    # @abstract Represents basic blockchain interface.
    #
    # Subclass and override abstract methods to implement
    # a peatio plugable blockchain.
    # Then you need to register your blockchain implementation.
    #
    # @see Bitcoin::Blockchain Bitcoin as example of Abstract imlementation
    #     (inside peatio source https://github.com/rubykube/peatio).
    #
    # @example
    #
    #   class MyBlockchain < Peatio::Abstract::Blockchain
    #     def fetch_block(block_number)
    #       # do something
    #     end
    #     ...
    #   end
    #
    #   # Register MyBlockchain as peatio plugable blockchain.
    #   Peatio::Blockchain.registry[:my_blockchain] = MyBlockchain.new
    #
    # @author
    #   Yaroslav Savchuk <savchukyarpolk@gmail.com> (https://github.com/ysv)
    class Abstract

      # Hash of features supported by blockchain.
      #
      # @abstract
      #
      # @see Abstract::SUPPORTED_FEATURES for list of features supported by peatio.
      #
      # @!attribute [r] features
      # @return [Hash] list of features supported by blockchain.
      attr_reader :features

      # List of features supported by peatio.
      #
      # @note Features list:
      #
      #   case_sensitive - defines if transactions and addresses of current
      #   blockchain are case_sensitive.
      #
      #   cash_addr_format - defines if blockchain supports Cash Address format
      #   for more info see (https://support.exodus.io/article/664-bitcoin-cash-address-format)
      SUPPORTED_FEATURES = %i[case_sensitive cash_addr_format].freeze


      # Current blockchain settings for performing API calls and building blocks.
      #
      # @abstract
      #
      # @see Abstract::SUPPORTED_SETTINGS for list of settings required by blockchain.
      #
      # @!attribute [r] settings
      # @return [Hash] current blockchain settings.
      attr_reader :settings

      # List of configurable settings.
      #
      # @see #configure
      SUPPORTED_SETTINGS = %i[server currencies].freeze


      # Abstract constructor.
      #
      # @abstract
      #
      # @example
      #   class MyBlockchain < Peatio::Abstract::Blockchain
      #
      #     DEFAULT_FEATURES = {case_sensitive: true, cash_addr_format: false}.freeze
      #
      #     # You could override default features by passing them to initializer.
      #     def initialize(my_custom_features = {})
      #       @features = DEFAULT_FEATURES.merge(my_custom_features)
      #     end
      #     ...
      #   end
      #
      #   # Register MyBlockchain as peatio plugable blockchain.
      #   custom_features = {cash_addr_format: true}
      #   Peatio::Blockchain.registry[:my_blockchain] = MyBlockchain.new(custom_features)
      def initialize(*)
        abstract_method
      end

      # Merges given configuration parameters with defined during initialization
      # and returns the result.
      #
      # @abstract
      #
      # @param [Hash] settings parameters to use.
      #
      # @option settings [String] :server Public blockchain API endpoint.
      # @option settings [Array<Hash>] :currencies List of currency hashes
      #   with :id,:base_factor,:options(deprecated) keys.
      #   Custom keys could be added by defining them in Currency #options.
      #
      # @return [Hash] merged settings.
      #
      # @note Be careful with your blockchain state after configure.
      #       Clean everything what could be related to other blockchain configuration.
      #       E.g. client state.
      def configure(settings = {})
        abstract_method
      end

      # Fetches blockchain block by calling API and builds block object
      # from response payload.
      #
      # @abstract
      #
      # @param block_number [Integer] the block number.
      # @return [Peatio::Block] the block object.
      # @raise [Peatio::Blockchain::ClientError] if error was raised
      #   on blockchain API call.
      def fetch_block!(block_number)
        abstract_method
      end

      # Fetches current blockchain height by calling API and returns it as number.
      #
      # @abstract
      #
      # @return [Integer] the current blockchain height.
      # @raise [Peatio::Blockchain::ClientError] if error was raised
      #   on blockchain API call.
      def latest_block_number
        abstract_method
      end

      # Fetches address balance of specific currency.
      #
      # @note Optional. Don't override this method if your blockchain
      # doesn't provide functionality to get balance by address.
      #
      # @param address [String] the address for requesting balance.
      # @param currency_id [String] which currency balance we need to request.
      # @return [BigDecimal] the current address balance.
      # @raise [Peatio::Blockchain::ClientError,Peatio::Blockchain::UnavailableAddressBalanceError]
      # if error was raised on blockchain API call ClientError is raised.
      # if blockchain API call was successful but we can't detect balance
      # for address Error is raised.
      def load_balance_of_address!(address, currency_id)
        raise Peatio::Blockchain::UnavailableAddressBalanceError
      end

      private

      # Method for defining other methods as abstract.
      #
      # @raise [MethodNotImplemented]
      def abstract_method
        method_not_implemented
      end
    end
  end
end
