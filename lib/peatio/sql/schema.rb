module Peatio::Sql
  class Schema
    attr_accessor :client

    def initialize(sql_client)
      @client = sql_client
    end

    def create_database(name)
      client.query("CREATE DATABASE IF NOT EXISTS `#{ name }`;")
    end

    def create_tables(options = {})
      statements = []
      statements << "DROP TABLE IF EXISTS `operations`;" if options[:drop_if_exists]
      statements << <<-EOF
CREATE TABLE IF NOT EXISTS `operations` (
    id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    code            TINYINT UNSIGNED NOT NULL,
    account_id      INT UNSIGNED NOT NULL,
    reference       INT UNSIGNED NOT NULL,
    debit           DECIMAL(32, 16) NOT NULL,
    credit          DECIMAL(32, 16) NOT NULL,
    created_at      DATETIME NOT NULL,
    updated_at      DATETIME NOT NULL,
    PRIMARY KEY     (id),
    INDEX `balance_key` (account_id, debit, credit)
) ENGINE = InnoDB;
EOF

      statements << "DROP TABLE IF EXISTS `orders`;" if options[:drop_if_exists]
      statements << <<EOF
CREATE TABLE IF NOT EXISTS`orders` (
  `id`          INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid`         INT(11) UNSIGNED NOT NULL,
  `bid`         VARCHAR(5) NOT NULL,
  `ask`         VARCHAR(5) NOT NULL,
  `market`      VARCHAR(10) NOT NULL,
  `price`       DECIMAL(32,16) DEFAULT NULL,
  `volume`      DECIMAL(32,16) NOT NULL,
  `fee`         DECIMAL(32,16) NOT NULL DEFAULT '0.0000000000000000',
  `type`        TINYINT UNSIGNED NOT NULL,
  `state`       TINYINT UNSIGNED NOT NULL,
  `created_at`  DATETIME NOT NULL,
  `updated_at`  DATETIME NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

      statements << "DROP TABLE IF EXISTS `trades`;" if options[:drop_if_exists]
      statements << <<EOF
CREATE TABLE IF NOT EXISTS `trades` (
  `id`          int(11) NOT NULL AUTO_INCREMENT,
  `market`      varchar(10) NOT NULL,
  `volume`      decimal(32,16) NOT NULL,
  `price`       decimal(32,16) NOT NULL,
  `ask_id`      int(11) NOT NULL,
  `bid_id`      int(11) NOT NULL,
  `ask_uid`     int(11) NOT NULL,
  `bid_uid`     int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF
      statements.each do |statement|
        puts statement
        client.query(statement)
      end
    end
  end
end
