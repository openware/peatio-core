module Peatio::BlockchainService
  module Helpers
    def cache_key(*suffixes)
      [self.class.name.underscore.gsub("/", ":"), suffixes].join(":")
    end
  end
end
