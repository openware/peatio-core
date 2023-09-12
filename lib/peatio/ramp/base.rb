# frozen_string_literal: true

module Peatio
  module Ramp
    class Base
      def ramp_on_transaction(currency_id, address, options = {})
        method_not_implemented
      end

      def ramp_off_transaction(currency_id, options = {})
        method_not_implemented
      end
    end
  end
end
