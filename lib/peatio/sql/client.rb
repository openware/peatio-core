module Peatio::Sql
  class Client
    attr_accessor :client, :config

    def initialize
      @config = {
        host: ENV["DATABASE_HOST"] || "localhost",
        username: ENV["DATABASE_USER"] || "root",
        password: ENV["DATABASE_PASS"] || "",
        port: ENV["DATABASE_PORT"] || "3306",
        database: ENV["DATABASE_NAME"] || "peatio_development",
      }
    end

    def connect
      @client = Mysql2::Client.new(config)
    end
  end
end
