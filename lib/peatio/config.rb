module Peatio
  class Config < OpenStruct

    def method_missing(sym, *args, &blk)
      name = sym.to_s.gsub(/[=!?]$/, '').to_sym
      value = super
      if value.nil?
        value = Config.new
        self[name] = value
      end
      return value
    end

  end
end
