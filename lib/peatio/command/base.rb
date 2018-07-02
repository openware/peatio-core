module Peatio::Command
  class Base < Clamp::Command
    def say(str)
      puts str
    end

    def sql_client
      @sql_client ||= Peatio::Sql::Client.new.connect
    end
  end
end
