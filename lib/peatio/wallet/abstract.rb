module Peatio
  module Wallet
    # @abstract Represents basic wallet interface.
    #
    # Subclass and override abstract methods to implement
    # a peatio plugable wallet.
    # Than you need to register your wallet implementation.
    #
    # @see Bitcoin::Wallet Bitcoin as example of Abstract imlementation.
    #
    # @example
    #
    #   class MyWallet < Peatio::Abstract::Wallet
    #     def create_address(options = {})
    #       # do something
    #     end
    #     ...
    #   end
    #
    #   # Register MyWallet as peatio plugable wallet.
    #   Peatio::Wallet.registry[:my_wallet] = MyWallet.new
    #
    # @author
    #   Yaroslav Savchuk <savchukyarpolk@gmail.com> (https://github.com/ysv)
    class Abstract
      # Current wallet settings for performing API calls.
      #
      # @abstract
      #
      # @!attribute [r] settings
      # @return [Hash] current wallet settings.
      attr_reader :settings

      # List of configurable settings.
      #
      # @see #configure
      SUPPORTED_SETTINGS = %i[wallet currency].freeze

      # Hash of features supported by wallet.
      #
      # @abstract
      #
      # @see Abstract::SUPPORTED_FEATURES for list of features supported by peatio.
      #
      # @!attribute [r] features
      # @return [Hash] list of features supported by wallet.
      attr_reader :features

      # List of features supported by peatio.
      #
      # @note Features list:
      #
      #   skip_deposit_collection - defines if deposit will be collected to 
      #   hot, warm, cold wallets.
      SUPPORTED_FEATURES = %i[skip_deposit_collection].freeze

      # Abstract constructor.
      #
      # @abstract
      #
      # @example
      #   class MyWallet< Peatio::Abstract::Wallet
      #
      #     # You could customize your wallet by passing features.
      #     def initialize(my_custom_features = {})
      #       @features = my_custom_features
      #     end
      #     ...
      #   end
      #
      #   # Register MyWallet as peatio plugable wallet.
      #   custom_features = {cash_addr_format: true}
      #   Peatio::Wallet.registry[:my_wallet] = MyWallet.new(custom_features)
      def initialize(*)
        abstract_method
      end

      # Merges given configuration parameters with defined during initialization
      # and returns the result.
      #
      # @abstract
      #
      # @param [Hash] settings configurations to use.
      # @option settings [Hash] :wallet Wallet settings for performing API calls.
      # With :address required key other settings could be customized
      # using Wallet#settings.
      # @option settings [Array<Hash>] :currencies List of currency hashes
      #   with :id,:base_factor,:options(deprecated) keys.
      #   Custom keys could be added by defining them in Currency #options.
      #
      # @return [Hash] merged settings.
      #
      # @note Be careful with your wallet state after configure.
      #       Clean everything what could be related to other wallet configuration.
      #       E.g. client state.
      def configure(settings = {})
        abstract_method
      end

      # Performs API call for address creation and returns it.
      #
      # @abstract
      #
      # @param [Hash] options
      # @options options [String] :uid User UID which requested address creation.
      #
      # @return [Hash] newly created blockchain address.
      #
      # @raise [Peatio::Blockchain::ClientError] if error was raised
      #   on wallet API call.
      #
      # @example
      #   { address: :fake_address,
      #     secret:  :changeme,
      #     details: { uid: account.member.uid } }
      def create_address!(options = {})
        abstract_method
      end

      # Performs API call for creating transaction and returns updated transaction.
      #
      # @abstract
      #
      # @param [Peatio::Transaction] transaction transaction with defined
      # to_address, amount & currency_id.
      #
      # @param [Hash] options
      # @options options [String] :subtract_fee Defines if you need to subtract
      #   fee from amount defined in transaction.
      #   It means that you need to deduct fee from amount declared in
      #   transaction and send only remaining amount.
      #   If transaction amount is 1.0 and estimated fee
      #   for sending transaction is 0.01 you need to send 0.09
      #   so 1.0 (0.9 + 0.1) will be subtracted from wallet balance
      #
      # @options options [String] custon options for wallet client.
      #
      # @return [Peatio::Transaction] transaction with updated hash.
      #
      # @raise [Peatio::Blockchain::ClientError] if error was raised
      #   on wallet API call.
      def create_transaction!(transaction, options = {})
        abstract_method
      end

      # Fetches address balance of specific currency.
      #
      # @note Optional. Don't override this method if your blockchain
      # doesn't provide functionality to get balance by address.
      #
      # @return [BigDecimal] the current address balance.
      #
      # @raise [Peatio::Blockchain::ClientError,Peatio::Blockchain::UnavailableAddressBalanceError]
      # if error was raised on wallet API call ClientError is raised.
      # if wallet API call was successful but we can't detect balance
      # for address Error is raised.
      def load_balance!
        raise Peatio::Wallet::UnavailableAddressBalanceError
      end

      # Performs API call(s) for preparing for deposit collection.
      # E.g deposits ETH for collecting ERC20 tokens in case of Ethereum blockchain.
      #
      # @note Optional. Override this method only if you need additional step
      # before deposit collection.
      #
      # @param [Peatio::Transaction] deposit_transaction transaction which
      # describes received deposit.
      #
      # @param [Array<Peatio::Transaction>] spread_transactions result of deposit
      # spread between wallets.
      #
      # @return [Array<Peatio::Transaction>] transaction created for
      # deposit collection preparing.
      # By default return empty [Array]
      def prepare_deposit_collection!(deposit_transaction, spread_transactions, deposit_currency)
        # This method is mostly used for coins which needs additional fees
        # to be deposited before deposit collection.
        []
      end

      private

      def abstract_method
        method_not_implemented
      end
    end
  end
end
