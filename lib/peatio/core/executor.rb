require "mysql2"
require "benchmark"

client = Mysql2::Client.new(
    host: "172.19.0.3",
    username: "root",
    password: "changeme",
    port: 3306,
    database: "peatio_development")

queries = [
    "INSERT INTO `trades` (`ask_id`, `ask_member_id`, `bid_id`, `bid_member_id`, `price`, `volume`, `funds`, `market_id`, `trend`, `created_at`, `updated_at`) VALUES (18711, 81, 18708, 82, 0.99999999, 50.0, 49.9999995, 'eurusd', 0, NOW(), NOW())",
    "UPDATE `accounts` SET `accounts`.`locked` = 3571.09999702 WHERE `accounts`.`id` = 164",
    "UPDATE `accounts` SET `accounts`.`balance` = 999995119.5335 WHERE `accounts`.`id` = 163",
    "UPDATE `accounts` SET `accounts`.`locked` = 4257.0 WHERE `accounts`.`id` = 161",
    "UPDATE `accounts` SET `accounts`.`balance` = 999995825.720262199325 WHERE `accounts`.`id` = 162",
    "UPDATE `orders` SET `volume` = 20.0, `locked` = 19.9999998, `funds_received` = 53.0, `trades_count` = 2, `updated_at` = '2018-06-25 23:44:37' WHERE `orders`.`id` = 18708",
    "UPDATE `orders` SET `volume` = 0.0, `locked` = 0.0, `funds_received` = 78.59999924, `trades_count` = 2, `state` = 200, `updated_at` = '2018-06-25 23:44:37' WHERE `orders`.`id` = 18711"
]

puts Benchmark.measure {
    1_000.times {

        client.query("begin")
        begin

            100.times {
                queries.each do |q|
                    client.query q
                end
            }

        rescue Mysql2::Error => e
            puts "+++++++ DB ERROR - ROLLING BACK ++++++++"
            puts e
            client.query("rollback")
            exit
        end
        client.query("commit") #commit the changes to the DB

    }
}

client.close

__END__

require 'mysql2/em'

EM.run do
   client = Mysql2::EM::Client.new(
        :host => '172.19.0.3',
        :username => 'root',
        :password => 'changeme',
        :port => 3306,
        :database => 'peatio_development')


    defer1 = client.query "SELECT sleep(3) as first_query"
    defer1.callback do |result|
        puts "Result: #{result.to_a.inspect}"
    end

end
