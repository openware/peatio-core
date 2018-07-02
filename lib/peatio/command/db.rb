module Peatio::Command::DB
  class Create < Peatio::Command::Base
    def execute
      client = Peatio::Sql::Client.new
      database_name = client.config.delete(:database)
      Peatio::Sql::Schema.new(client.connect).create_database(database_name)
    end
  end

  class Migrate < Peatio::Command::Base
    def execute
      Peatio::Sql::Schema.new(sql_client).create_tables
    end
  end

  class Root < Peatio::Command::Base
    subcommand "create", "Create database", Peatio::Command::DB::Create
    subcommand "migrate", "Create tables", Peatio::Command::DB::Migrate
  end
end
