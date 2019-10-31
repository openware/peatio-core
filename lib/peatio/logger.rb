# frozen_string_literal: true

module Peatio
  class Logger
    class << self
      def logger
        @logger ||= ::Logger.new(STDERR, level: level)
      end

      def level
        (ENV["LOG_LEVEL"] || "info").downcase.to_sym
      end

      def debug(progname=nil, &block)
        logger.debug(progname, &block)
      end

      def info(progname=nil, &block)
        logger.info(progname, &block)
      end

      def warn(progname=nil, &block)
        logger.warn(progname, &block)
      end

      def error(progname=nil, &block)
        logger.error(progname, &block)
      end

      def fatal(progname=nil, &block)
        logger.fatal(progname, &block)
      end

      def unknown(progname=nil, &block)
        logger.unknown(progname, &block)
      end
    end
  end
end
